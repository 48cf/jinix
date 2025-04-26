add_executable(native-ical-glib-src-generator IMPORTED GLOBAL)
set_target_properties(native-ical-glib-src-generator PROPERTIES IMPORTED_LOCATION "$ENV{ICAL_NATIVE_TOOL}")