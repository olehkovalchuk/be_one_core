class SettingValidation
  class Base
    include Validation::Base
    crudify do
      attribute :code, String, uniqe: true
      attribute :setting_type, String, default: 'string'
      attribute :value
      validates :code, :value, :setting_type, presence: true
    end
  end
end