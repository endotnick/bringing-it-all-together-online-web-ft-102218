require_relative "../config/environment.rb"

class Dog
  attr_accessor :name, :breed, :id

  def initialize(id: nil, name:, breed:)
    @id = id 
    @name = name 
    @breed = breed
  end

  def self.create_table
    create_dogs = <<-SQL 
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      )
      SQL
    DB[:conn].execute(create_dogs)
  end

  def self.drop_table
    drop_dogs = 'DROP TABLE IF EXISTS dogs'
    DB[:conn].execute(drop_dogs)
  end

  def save
    if self.id
      self.update
    else
      insert_dogs = <<-SQL 
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      SQL
      DB[:conn].execute(insert_dogs, self.name, self.breed)
      select_last = 'SELECT last_insert_rowid() FROM dogs'
      self.id = DB[:conn].execute(select_last)[0][0]
    end
    self
  end

  def self.create(name:, breed:)
    self.new(name: name, breed: breed).tap do |dog|
      dog.save
    end
  end

  def self.new_from_db(record)
    id = record[0]
    name = record[1]
    breed = record[2]
    self.new(id: id, name: name, breed: breed)
  end

  def self.find_or_create_by(name:, breed:)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE name = ?
      AND breed = ?
      LIMIT 1
    SQL
    result = DB[:conn].execute(sql,name, breed)    
    !result.empty? ? self.new_from_db(result[0]) : self.create(name: name, breed: breed)      
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE name = ?
      LIMIT 1
    SQL

    DB[:conn].execute(sql,name).map do |record|
      self.new_from_db(record)
    end.first
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE id = ?
      LIMIT 1
    SQL

    DB[:conn].execute(sql, id).map do |record|
      self.new_from_db(record)
    end.first
  end

  def update
    sql = 'UPDATE dogs SET name = ?, breed = ? WHERE id = ?'
    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end
end
