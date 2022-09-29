/* This file is part of GEGL
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
 */

#ifndef __GEGL_BUFFER_SWAP_PRIVATE_H__
#define __GEGL_BUFFER_SWAP_PRIVATE_H__


#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

void   gegl_buffer_swap_init    (void);
void   gegl_buffer_swap_cleanup (void);

G_END_DECLS

#endif
