require 'digest/sha2'

# Manages hashed passwords

module BeOneCore
  module Password
    class << self
      # Creates salted password
      # @param password [String] plain text password
      # @return [String] salted password hash
      def create(password)
        salt = self.salt
        hash = self.hash(password,salt)
        self.store(hash, salt)
      end

      # Checks password
      # @param password [String] plain text password
      # @param store [String] salted password hash
      # @return [Boolean] if password matches stored hash
      def check(password, store)
        hash = self.get_hash(store)
        salt = self.get_salt(store)
        self.hash(password,salt) == hash
      end

      def random( length = 10 )
        (('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a).sort_by { rand }.join[0...length]
      end



      def salt
        salt = ""
        Kernel.rand(64..80).times { salt << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
        salt
      end

      protected

      def hash(password,salt)
        OpenSSL::Digest::SHA512.new("#{password}:#{salt}").hexdigest
      end

      def store(hash, salt)
        hash + salt
      end

      def get_hash(store)
        store[0..127]
      end

      def get_salt(store)
        store[128..-1]
      end
    end
  end 
end

