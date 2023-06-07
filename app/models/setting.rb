class Setting < ActiveRecord::Base

  self.table_name = "#{Rails.application.class.parent_name.underscore}_settings"
  
  after_save {|record| Rails.cache.delete( Setting._cache_key( record ) ) }
  def self.get( key )
    Rails.cache.fetch( Setting._cache_key( key ) , expires_in: 1.day ){
      self.find_by(code: key).try(:value)
    }
  end

  def self._cache_key( key )
    "be_one_core_settings_#{key}"
  end
end