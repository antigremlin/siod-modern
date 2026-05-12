project('siod', 'c',
  version : '3.6',
  meson_version : '>=1.9.0',
  default_options : [
    'c_std=c23',
    'warning_level=2',
    'buildtype=debugoptimized',
  ],
)

cc = meson.get_compiler('c')

# On macOS, 'unix' is not predefined; the code guards POSIX includes with it.
common_c_args = ['-Dunix']

# Sanitizers (enable with -Dsanitize=true)
if get_option('sanitize')
  san_flags = ['-fsanitize=address,undefined', '-fno-sanitize-recover=all']
  add_project_arguments(san_flags, language : 'c')
  add_project_link_arguments(san_flags, language : 'c')
endif

# Core interpreter library (SIOD_OBJS_COMMON from Makefile)
libsiod = static_library('siod',
  'slib.c',
  'sliba.c',
  'trace.c',
  'slibu.c',
  'md5.c',
  c_args : common_c_args,
)

# Main executable
executable('siod',
  'siod.c',
  c_args : common_c_args,
  link_with : libsiod,
)
