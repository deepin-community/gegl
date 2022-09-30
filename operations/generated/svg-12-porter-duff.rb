#!/usr/bin/env ruby
# encoding: utf-8

copyright = '
/* !!!! AUTOGENERATED FILE generated by svg-12-porter-duff.rb !!!!!
 *
 * This file is an image processing operation for GEGL
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
 *  Copyright 2006, 2007 Øyvind Kolås <pippin@gimp.org>
 *            2007 John Marshall
 *            2013 Daniel Sabo
 *
 * SVG rendering modes; see:
 *     http://www.w3.org/TR/SVG12/rendering.html
 *     http://www.w3.org/TR/2004/WD-SVG12-20041027/rendering.html#comp-op-prop
 *
 *     aA = aux(src) alpha      aB = in(dst) alpha      aD = out alpha
 *     cA = aux(src) colour     cB = in(dst) colour     cD = out colour
 *
 * !!!! AUTOGENERATED FILE !!!!!
 */'

a = [
      ['clear',         '0.0f',
                        '0.0f',
       false, 'f1b3ab0f1e84ec5882f23aee0a0c68f6'],
      ['src',           'cA',
                        'aA',
       false, 'f6a66e7e92224fb5df43d15d8faf4262'],
      ['dst',           'cB',
                        'aB',
       true, 'ffb9e86edb25bc92e8d4e68f59bbb04b'],
#      ['src_over',      'cA + cB * (1.0f - aA)',
#                        'aA + aB - aA * aB',
#       false],
      ['dst_over',      'cB + cA * (1.0f - aB)',
                        'aA + aB - aA * aB',
       true, '2ae31f32b8b4e788e5f631827cad51b4'],
      ['dst_in',        'cB * aA', # <- XXX: typo?
                        'aA * aB',
       false, 'e7e478208bc463c6894049aefd1616b5'],
      ['src_out',       'cA * (1.0f - aB)',
                        'aA * (1.0f - aB)',
       false, '64265021e1681dfc4485349cfe4f8a9e'],
      ['dst_out',       'cB * (1.0f - aA)',
                        'aB * (1.0f - aA)',
       true, 'b0ffe0c9b9a5a48d21df751ce576ffa9'],
      ['src_atop',      'cA * aB + cB * (1.0f - aA)',
                        'aB',
       true, '7cb5948ed7e041e6f88b4939d352edf8'],

      ['dst_atop',      'cB * aA + cA * (1.0f - aB)',
                        'aA',
        false, 'daeb2e2e1ae75898af7db31934e240fb'],
      ['xor',           'cA * (1.0f - aB)+ cB * (1.0f - aA)',
                        'aA + aB - 2.0f * aA * aB',
       true, 'd5c452c163acf983677da4dd5e5dca09'],
    ]

b = [ ['src_in',        'cA * aB',  # the bounding box of this mode is the
                        'aA * aB',
       '2663ce60fd1362bb014d22534ab34ac7']]  # bounding box of the input only.

file_head1 = '
#include "config.h"
#include <glib/gi18n-lib.h>


#ifdef GEGL_PROPERTIES

property_boolean (srgb, _("sRGB"), FALSE)
    description (_("Use sRGB gamma instead of linear"))

#else
'

file_head2 = '
static void prepare (GeglOperation *operation)
{
  const Babl *format = gegl_operation_get_source_format (operation, "input");
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
process (GeglOperation        *op,
         void                *in_buf,
         void                *aux_buf,
         void                *out_buf,
         glong                n_pixels,
         const GeglRectangle *roi,
         gint                 level)
{
  gint i;
  gfloat * GEGL_ALIGNED in = in_buf;
  gfloat * GEGL_ALIGNED aux = aux_buf;
  gfloat * GEGL_ALIGNED out = out_buf;
  const Babl *format = gegl_operation_get_format (op, "output");
  gint    components = babl_format_get_n_components (format);
  gint    alpha      = components-1;
'

file_tail1 = '

static void
gegl_op_class_init (GeglOpClass *klass)
{
  GeglOperationClass              *operation_class;
  GeglOperationPointComposerClass *point_composer_class;

  operation_class      = GEGL_OPERATION_CLASS (klass);
  point_composer_class = GEGL_OPERATION_POINT_COMPOSER_CLASS (klass);

  point_composer_class->process = process;
  operation_class->prepare = prepare;

'

file_tail2 = ' 

}

#endif
'

a.each do
    |item|

    name     = item[0] + ''
    name.gsub!(/_/, '-')
    filename = name + '.c'

    puts "generating #{filename}"
    file = File.open(filename, 'w')

    capitalized = name.capitalize
    swapcased   = name.swapcase
    c_formula   = item[1]
    a_formula   = item[2]

    file.write copyright
    file.write file_head1
    file.write "
#define GEGL_OP_POINT_COMPOSER
#define GEGL_OP_NAME         #{item[0]}
#define GEGL_OP_C_FILE        \"#{filename}\"

#include \"gegl-op.h\"
"
    file.write file_head2

    if item[3]
      file.write "
  if (!aux)
    {
      for (i = 0; i < n_pixels; i++)
        {
          gint   j;
          gfloat aA G_GNUC_UNUSED, aB G_GNUC_UNUSED, aD G_GNUC_UNUSED;

          aB = alpha?in[alpha]:1.0f;
          aA = 0.0f;
          aD = #{a_formula};

          for (j = 0; j < alpha; j++)
            {
              gfloat cA G_GNUC_UNUSED, cB G_GNUC_UNUSED;

              cB = in[j];
              cA = 0.0f;
              out[j] = #{c_formula};
            }
          out[alpha] = aD;
          in  += components;
          out += components;
        }
    }
  else"
    else
      file.write "
  if (!aux)
    return TRUE;
  else"
    end

    file.write "
    {
      for (i = 0; i < n_pixels; i++)
        {
          gint   j;
          gfloat aA G_GNUC_UNUSED, aB G_GNUC_UNUSED, aD G_GNUC_UNUSED;

          aB = in[alpha];
          aA = aux[alpha];
          aD = #{a_formula};

          for (j = 0; j < alpha; j++)
            {
              gfloat cA G_GNUC_UNUSED, cB G_GNUC_UNUSED;

              cB = in[j];
              cA = aux[j];
              out[j] = #{c_formula};
            }
          out[alpha] = aD;
          in  += components;
          aux += components;
          out += components;
        }
    }
  return TRUE;
}
"
  file.write file_tail1
  file.write "
  gegl_operation_class_set_keys (operation_class,
    \"name\"       , \"svg:#{name}\",
    \"compat-name\", \"gegl:#{name}\",
    \"title\"      , \"#{name.capitalize}\",
    \"reference-hash\" , \"#{item[4]}\",
    \"categories\" , \"compositors:porter-duff\",
    \"description\",
        _(\"Porter Duff operation #{name} (d = #{c_formula})\"),
        NULL);
"
  file.write file_tail2
  file.close
end





b.each do
    |item|

    name     = item[0] + ''
    name.gsub!(/_/, '-')
    filename = name + '.c'

    puts "generating #{filename}"
    file = File.open(filename, 'w')

    capitalized = name.capitalize
    swapcased   = name.swapcase
    c_formula   = item[1]
    a_formula   = item[2]

    file.write copyright
    file.write file_head1
    file.write "
#define GEGL_OP_POINT_COMPOSER
#define GEGL_OP_NAME         #{item[0]}
#define GEGL_OP_C_FILE        \"#{filename}\"

#include \"gegl-op.h\"
"
    file.write file_head2
    file.write "
  if (!aux)
    return TRUE;

  for (i = 0; i < n_pixels; i++)
    {
      gint   j;
      gfloat aA G_GNUC_UNUSED, aB G_GNUC_UNUSED, aD G_GNUC_UNUSED;

      aB = in[alpha];
      aA = aux[alpha];

      aD = #{a_formula};

      for (j = 0; j < alpha; j++)
        {
          gfloat cA G_GNUC_UNUSED, cB G_GNUC_UNUSED;

          cB = in[j];
          cA = aux[j];
          out[j] = #{c_formula};
        }
      out[alpha] = aD;
      in  += components;
      aux += components;
      out += components;
    }
  return TRUE;
}

static GeglRectangle get_bounding_box (GeglOperation *self)
{
  GeglRectangle ret={0,0,1,1};
  GeglRectangle *in_rect = gegl_operation_source_get_bounding_box (self, \"input\");
  if (in_rect)
    ret = *in_rect;
  return ret;
}


"
  file.write file_tail1
  file.write "
  operation_class->get_bounding_box = get_bounding_box;

  gegl_operation_class_set_keys (operation_class,
  \"name\"      , \"svg:#{name}\",
  \"compat-name\", \"gegl:#{name}\",
  \"title\"     , \"#{name.capitalize}\",
    \"reference-hash\" , \"#{item[3]}\",
  \"categories\", \"compositors:porter-duff\",
  \"description\" ,
        _(\"Porter Duff compositing operation #{name} (formula:   #{c_formula})\"),
        NULL);
"
  file.write file_tail2
  file.close
end