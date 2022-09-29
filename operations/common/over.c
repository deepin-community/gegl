/* This file is an image processing operation for GEGL
 *
 * GEGL is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * GEGL is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with GEGL; if not, see <https://www.gnu.org/licenses/>.
 *
 * Copyright 2006-2009 Øyvind Kolås <pippin@gimp.org>
 */

#include "config.h"
#include <glib/gi18n-lib.h>


#ifdef GEGL_PROPERTIES

property_boolean (srgb, _("sRGB"), FALSE)
    description (_("Use sRGB gamma instead of linear"))

#else

#define GEGL_OP_POINT_COMPOSER
#define GEGL_OP_NAME     over
#define GEGL_OP_C_SOURCE over.c

#include "gegl-op.h"

static void opencl_prepare (GeglOperation *operation)
{
  GeglProperties *o = GEGL_PROPERTIES (operation);
  const Babl *space = gegl_operation_get_source_space (operation, "input");

  const Babl *format;

  if (o->srgb)
    format = babl_format_with_space ("R~aG~aB~aA float", space);
  else
    format = babl_format_with_space ("RaGaBaA float", space);

  gegl_operation_set_format (operation, "input", format);
  gegl_operation_set_format (operation, "aux", format);
  gegl_operation_set_format (operation, "output", format);
}

static void prepare (GeglOperation *operation)
{
  const Babl *format = gegl_operation_get_source_format (operation, "input");

  if (gegl_operation_use_opencl (operation))
  {
    opencl_prepare (operation);
    return;
  }

  if (!format)
    format = gegl_operation_get_source_format (operation, "aux");

  if(GEGL_PROPERTIES (operation)->srgb)
    format = gegl_babl_variant (format, GEGL_BABL_VARIANT_PERCEPTUAL_PREMULTIPLIED);
  else
    format = gegl_babl_variant (format, GEGL_BABL_VARIANT_LINEAR_PREMULTIPLIED);

  gegl_operation_set_format (operation, "input",  format);
  gegl_operation_set_format (operation, "aux",    format);
  gegl_operation_set_format (operation, "output", format);
}

static gboolean
process (GeglOperation       *op,
         void                *in_buf,
         void                *aux_buf,
         void                *out_buf,
         glong                n_pixels,
         const GeglRectangle *roi,
         gint                 level)
{
  const Babl *format = gegl_operation_get_format (op, "output");
  gint  components = babl_format_get_n_components (format);
  gint  alpha = components - 1;

  gfloat * GEGL_ALIGNED in = in_buf;
  gfloat * GEGL_ALIGNED aux = aux_buf;
  gfloat * GEGL_ALIGNED out = out_buf;


  if (aux==NULL)
    return TRUE;

  while (n_pixels--)
  {
    for (int i = 0; i < alpha; i ++)
      out[i] = aux[i] + in[i] * (1.0f - aux[alpha]);
    out[alpha] = aux[alpha] + in[alpha] - aux[alpha] * in[alpha];
    in  += components;
    aux += components;
    out += components;
  }
  return TRUE;
}

#include "opencl/svg-src-over.cl.h"

static gboolean
cl_process (GeglOperation       *operation,
            cl_mem               in_tex,
            cl_mem               aux_tex,
            cl_mem               out_tex,
            size_t               global_worksize,
            const GeglRectangle *roi,
            gint                 level)
{
  GeglOperationClass *operation_class = GEGL_OPERATION_GET_CLASS (operation);
  cl_int cl_err = 0;

  /* The kernel will have been compiled by our parent class */
  if (!operation_class->cl_data)
    return TRUE;

  cl_err = gegl_cl_set_kernel_args (operation_class->cl_data->kernel[0],
                                    sizeof(cl_mem), &in_tex,
                                    sizeof(cl_mem), &aux_tex,
                                    sizeof(cl_mem), &out_tex,
                                    NULL);
  CL_CHECK;

  cl_err = gegl_clEnqueueNDRangeKernel (gegl_cl_get_command_queue (),
                                        operation_class->cl_data->kernel[0], 1,
                                        NULL, &global_worksize, NULL,
                                        0, NULL, NULL);
  CL_CHECK;

  return FALSE;

error:
  return TRUE;
}

/* Fast paths */
static gboolean operation_process (GeglOperation        *operation,
                                   GeglOperationContext *context,
                                   const gchar          *output_prop,
                                   const GeglRectangle  *result,
                                   gint                  level)
{
  GeglOperationClass  *operation_class;
  gpointer input, aux;
  operation_class = GEGL_OPERATION_CLASS (gegl_op_parent_class);

  /* get the raw values this does not increase the reference count */
  input = gegl_operation_context_get_object (context, "input");
  aux = gegl_operation_context_get_object (context, "aux");

  /* pass the input/aux buffers directly through if they are alone*/
  {
    const GeglRectangle *in_extent = NULL;
    const GeglRectangle *aux_extent = NULL;

    if (input)
      in_extent = gegl_buffer_get_abyss (input);

    if ((!input ||
        (aux && !gegl_rectangle_intersect (NULL, in_extent, result))))
      {
         gegl_operation_context_take_object (context, "output",
                                             g_object_ref (aux));
         return TRUE;
      }
    if (aux)
      aux_extent = gegl_buffer_get_abyss (aux);

    if (!aux ||
        (input && !gegl_rectangle_intersect (NULL, aux_extent, result)))
      {
        gegl_operation_context_take_object (context, "output",
                                            g_object_ref (input));
        return TRUE;
      }
  }
  /* chain up, which will create the needed buffers for our actual
   * process function
   */
  return operation_class->process (operation, context, output_prop, result, level);
}

static void
gegl_op_class_init (GeglOpClass *klass)
{
  GeglOperationClass              *operation_class;
  GeglOperationPointComposerClass *point_composer_class;

  operation_class      = GEGL_OPERATION_CLASS (klass);
  point_composer_class = GEGL_OPERATION_POINT_COMPOSER_CLASS (klass);
  operation_class->prepare = prepare;
  operation_class->process = operation_process;

  point_composer_class->cl_process = cl_process;
  point_composer_class->process    = process;

  gegl_operation_class_set_keys (operation_class,
    "name"       , "svg:src-over",
    "title",       _("Normal compositing"),
    "compat-name", "gegl:over",
    "categories" , "compositors:porter-duff",
    "reference-hash", "b0fd7eded2a894bcdf1a395b01b09e44",
    "description",
          _("Porter Duff operation over (also known as normal mode, and src-over) (d = cA + cB * (1 - aA))"),
    "cl-source"  , svg_src_over_cl_source,
    NULL);
}

#endif
