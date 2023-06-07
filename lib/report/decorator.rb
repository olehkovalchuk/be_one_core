require "spreadsheet"
module Report
  module Decorator

    class Base
      def self.headers(keys)
        keys.map{ |attr| I18n.t("report.#{attr}") }
      end
    end

    class Xml < Base
      def self.report( data, keys )
        raise ArgumentError, "Param must be an instance of Array" unless data.kind_of?(Array)
        Report::Decorator::Raw.report(data, keys).to_xml(root: :bookings, skip_types: true)
      end
    end

    class Json < Base
      def self.report( data, keys )
        raise ArgumentError, "Param must be an instance of Array" unless data.kind_of?(Array)
        Report::Decorator::Raw.report(data, keys).to_json
      end
    end

    class Raw < Base
      def self.report( data, keys )
        raise ArgumentError, "Param must be an instance of Array" unless data.kind_of?(Array)
        data.map do |line|
          line.each.with_index.inject({}) do |hash, (value,idx)|
            hash[keys[idx]] = value
            hash
          end
        end
      end
    end

    class Xls < Base
      def self.report( data, keys )
        raise ArgumentError, "Param must be an instance of Array" unless data.kind_of?(Array)
        book = ::Spreadsheet::Workbook.new
        sheet = book.create_worksheet
        headings = self.headers(keys)
        sheet.row(0).default_format = ::Spreadsheet::Format.new( weight: :bold, horizontal_align: :center, bottom: :thick )
        sheet.row(0).replace(headings)
        headings.each_with_index{|col,idx| sheet.column(idx).width = 25 }
        data.each_with_index do |line,i|
          sheet.row((i+1)).default_format = ::Spreadsheet::Format.new( horizontal_align: :center )
          sheet.row((i+1)).replace(line)
        end
        book
      end
    end

    class Csv < Base
      def self.report( data, keys )
        raise ArgumentError, "Param must be an instance of Array" unless data.kind_of?(Array)
        result = [self.headers(keys).join("|")]
        result << data.map{|line| line.join("|") }
        result.join("\n")
      end
    end



  end
end
