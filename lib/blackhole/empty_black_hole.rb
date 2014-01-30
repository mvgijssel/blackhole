class BlackHole < ::BasicObject

  class EmptyBlackHole

    # class variables should always be instantiated
    @@_instance = nil

    def self.instance

      unless @@_instance

        @@_instance = EmptyBlackHole.new

      end

      # return the instance
      @@_instance

    end

  end

end
