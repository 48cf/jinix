project('mlibc-run-wrapper', 'c', default_options : ['c_std=gnu23'])

dl = dependency('dl')

shared_library(
    'mlibc-run-wrapper',
    'main.c',
    dependencies: [dl],
    install: true,
)
