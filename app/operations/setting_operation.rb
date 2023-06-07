module SettingOperation
  class Base
    include Operation::Base
    crudify do
      model_name Setting
    end
  end
end