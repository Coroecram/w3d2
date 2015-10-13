require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')

    self.results_as_hash = true

    self.type_translation = true
  end
end

class User
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      users.id = ?
    SQL

    results.map { |result| User.new(result) }.first
  end

  attr_accessor :id, :f_name, :l_name

  def initialize(options = {})
    @id = options['id']
    @f_name = options['f_name']
    @l_name = options['l_name']
  end

  def self.find_by_name(f_name, l_name)
    results = QuestionsDatabase.instance.execute(<<-SQL, f_name, l_name)
    SELECT
      *
    FROM
      users
    WHERE
      users.f_name = ?
      AND users.l_name = ?
    SQL

    results.map { |result| User.new(result) }.first
  end

  def authored_questions
    results = Question.find_by_author_id(id)
  end

  def authored_replies
    results = Reply.find_by_user_id(id)
  end

end

class Question
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      questions.id = ?
    SQL

    results.map { |result| Question.new(result) }.first
  end

  def self.find_by_author_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      questions.user_id = ?
    SQL

    results.map { |result| Question.new(result) }.first
  end

  def author
    User.find_by_id(user_id)
  end

  def replies
    Reply.find_by_question_id(id)
  end


  attr_accessor :id, :title, :body, :user_id

  def initialize(options = {})
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end
end

class QuestionFollow
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_follows
    WHERE
      question_follows.id = ?
    SQL

    results.map { |result| QuestionFollow.new(result) }.first
  end

  def self.followers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      question_follows
    WHERE
      question_follows.question_id = ?
    SQL

    results.map { |user_id| User.find_by_id(user_id) }

  end

  attr_accessor :id, :user_id, :question_id

  def initialize(options = {})
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end

class Reply
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.id = ?
    SQL

    results.map { |result| Reply.new(result) }.first
  end

  def self.find_by_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.user_id = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def self.find_by_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.question_id = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def author
    User.find_by_id(user_id)
  end

  def question
    Question.find_by_id(question_id)
  end

  def parent_reply
    Reply.find_by_id(parent_id)
  end

  def child_replies
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.parent_id = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  attr_accessor :id, :body, :question_id, :parent_id, :user_id

  def initialize(options = {})
    @id = options['id']
    @body = options['body']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @user_id = options['user_id']
  end

end

class QuestionLike
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_likes
    WHERE
      question_likes.id = ?
    SQL

    results.map { |result| QuestionLike.new(result) }.first
  end

  attr_accessor :id, :user_id, :question_id

  def initialize(options = {})
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

end











# class Department
#   def self.all
#
#     results = SchoolDatabase.instance.execute('SELECT * FROM departments')
#     results.map { |result| Department.new(result) }
#   end
#
#   attr_accessor :id, :name
#
#   def initialize(options = {})
#     @id = options['id']
#     @name = options['name']
#   end
#
#   def create
#
#     raise 'already saved!' unless self.id.nil?
#
#     SchoolDatabase.instance.execute(<<-SQL, name)
#       INSERT INTO
#         departments (name)
#       VALUES
#         (?)
#     SQL
#
#     @id = SchoolDatabase.instance.last_insert_row_id
#   end
#
#   def professors
#     results = SchoolDatabase.instance.execute(<<-SQL, self.id)
#       SELECT
#         *
#       FROM
#         professors
#       WHERE
#         professors.department_id = ?
#     SQL
#
#     results.map { |result| Professor.new(result) }
#   end
# end
#
# class Professor
#   attr_accessor :id, :first_name, :last_name, :department_id
#
#   def initialize(options = {})
#     @id, @first_name, @last_name, @department_id =
#       options.values_at('id', 'first_name', 'last_name', 'department_id')
#   end
#
#   def create
#     raise 'already saved!' unless self.id.nil?
#
#     params = [self.first_name, self.last_name, self.department_id]
#     SchoolDatabase.instance.execute(<<-SQL, *params)
#       INSERT INTO
#         professors (first_name, last_name, department_id)
#       VALUES
#         (?, ?, ?)
#     SQL
#
#     @id = SchoolDatabase.instance.last_insert_row_id
#   end
# end
