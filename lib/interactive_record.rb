require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord


    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        sql = <<-SQL
            PRAGMA table_info(#{self.table_name})
        SQL
        column_names = []
        DB[:conn].execute(sql).each do |column|
            column_names << column["name"]
        end
        column_names.compact
    end

    def initialize(options = {})
        options.each do |attribute, value|
            self.send("#{attribute}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|name| name == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |name|
            values << "'#{send(name)}'" unless send(name).nil?
        end
        values.join(", ")
    end

    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = <<-SQL
            SELECT * FROM #{table_name}
            WHERE name = ?
        SQL

        DB[:conn].execute(sql, name)
    end

    def self.find_by(attribute)
        column = attribute.keys.first.to_s
        value = attribute.keys.first
        if value.is_a? Integer
            value = attribute.keys.first.to_i
        end

        sql = <<-SQL
            SELECT * FROM #{table_name}
            WHERE #{column} = #{value}
        SQL

        [] << DB[:conn].execute(sql)[0]

    end



end
