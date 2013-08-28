# Yes, I am going to polute the global namespace in a strange way by including
# `Kracken` but stuffing the generator under `OmniAuth::Radius::Rails` seems
# strange too. So this file is here to let bundler load the lib without an
# explicit `require: 'kracken'`

require_relative 'kracken'

