module Analytics
  class Transform
    def self.to_csv(export)
      CSV.generate do |csv|
        csv << export.headers

        export.rows.each do |row|
          csv << row
        end
      end
    end
  end
end
