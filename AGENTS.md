This is SIOD (scheme-in-one-defun), an old Scheme interpreter.
It should roughly implment R3RS Scheme.
Our goal in this project is to modernise the source code and port it to C23.

Initially, we are using the following tools (available on the path, provided by mise):
- meson for the build files
- ninja as the backend
- clang as the compiler (available via xcode-select)
