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

common_c_args = []
common_deps = []

# Preserve the legacy platform guards while the source is being modernized.
if host_machine.system() == 'windows'
  common_c_args += ['-DWIN32']
else
  common_c_args += ['-Dunix']
  common_deps += cc.find_library('dl', required : false)
endif

common_deps += cc.find_library('m', required : false)

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
  dependencies : common_deps,
)

# Main executable
siod_exe = executable('siod',
  'siod.c',
  c_args : common_c_args,
  dependencies : common_deps,
  link_with : libsiod,
)

test('core-suite', siod_exe,
  args : ['test-suite.scm'],
  workdir : meson.project_source_root(),
)
