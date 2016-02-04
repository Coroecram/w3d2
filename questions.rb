require 'singleton'
require 'sqlite3'
require 'byebug'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')

    self.results_as_hash = true

    self.type_translation = true
  end
end

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

class SuperTable

  NAME_CONVERT = {
    "User" => "users",
    "Question" => "questions",
    "QuestionFollow" => "question_follows",
    "Reply" => "replies",
    "QuestionLike" => "question_likes"
  }

  def self.find_by_id(id)
    table = NAME_CONVERT[self.to_s]
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table}
      WHERE
        #{table}.id = ?
    SQL

    results.map { |result| self.new(result) }.first
  end

  def self.all
    table = NAME_CONVERT[self.to_s]
    results = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table}
    SQL

    results.map { |result| self.new(result) }
  end


  def save
    table = NAME_CONVERT[self.class.to_s]
    inter_array = []
    iv_names = self.instance_variables
    iv_names_clean = iv_names.map { |var| var.to_s[1..-1] }[1..-1]
    params = iv_names_clean.map { |var| self.send(var) }
    var_insert = "(#{iv_names_clean.join(', ')})"
    params.length.times { inter_array << "?" }
    question_marks = "(#{inter_array.join(", ")})"
    if self.id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, *params)
        INSERT INTO
          #{table} #{var_insert}
        VALUES
          #{question_marks}
      SQL

      self.id = QuestionsDatabase.instance.last_insert_row_id
      else
        set_cols = "#{iv_names_clean.join(" = ?, ")} = ?"
        params << self.id
        QuestionsDatabase.instance.execute(<<-SQL, *params)
          UPDATE
            #{table}
          SET
            #{set_cols}
          WHERE
            #{table}.id = ?
        SQL
      end
    end

    # IN PROGRESS #

  # def self.where(options = {})
  #   cols = options.keys.map { |key| key.to_s }
  #
  #   results = QuestionsDatabase.instance.execute(<<-SQL)
  #     SELECT
  #       options keys
  #     FROM
  #       #{self.all}
  #     WHERE
  #       options value
  #   SQL
  # end

end

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

class User < SuperTable
  # def self.find_by_id(id)
    # results = QuestionsDatabase.instance.execute(<<-SQL, id)
    #   SELECT
    #     *
    #   FROM
    #     users
    #   WHERE
    #     users.id = ?
    # SQL
  #
  # end

  attr_accessor :id, :f_name, :l_name

  def initialize(options = {})
    @id = options['id']
    @f_name = options['f_name']
    @l_name = options['l_name']
  end

  # def save
  #   if self.id.nil?
  #     params = [f_name, l_name]
  #     QuestionsDatabase.instance.execute(<<-SQL, *params)
  #       INSERT INTO
  #         users (f_name, l_name)
  #       VALUES
  #         (?, ?)
  #     SQL
  #
  #     @id = QuestionsDatabase.instance.last_insert_row_id
  #     else
  #       params = [f_name, l_name, self.id]
  #       QuestionsDatabase.instance.execute(<<-SQL, *params)
  #         UPDATE
  #           users
  #         SET
  #           f_name = ?, l_name = ?
  #         WHERE
  #           users.id = ?
  #       SQL
  #     end
  #   end



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

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(id)
  end

  def average_karma
    result = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        CAST (COUNT(question_likes.id) AS FLOAT)/COUNT(DISTINCT questions.id) AS average_karma
      FROM
        question_likes
      LEFT OUTER JOIN
        questions
        ON question_likes.question_id = questions.id
      WHERE
        questions.user_id = ?
    SQL

    result.first['average_karma']
  end
end

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

class Question < SuperTable

  # def self.find_by_id(id)
  #   results = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       questions
  #     WHERE
  #       questions.id = ?
  #   SQL
  #
  #   results.map { |result| Question.new(result) }.first
  # end

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

  def followers
    QuestionFollow.followers_for_question_id(id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  attr_accessor :id, :title, :body, :user_id

  def initialize(options = {})
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end
end

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

class QuestionFollow < SuperTable

  # def self.find_by_id(id)
  #   results = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       question_follows
  #     WHERE
  #       question_follows.id = ?
  #   SQL
  #
  #   results.map { |result| QuestionFollow.new(result) }.first
  # end

  def self.followers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id
      FROM
        question_follows
      JOIN
        users
        ON question_follows.user_id = users.id
      WHERE
        question_follows.question_id = ?
    SQL

    results.map { |user_id| User.find_by_id(user_id['id']) }
  end

  def self.followed_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id
      FROM
        question_follows
      JOIN
        questions
        ON question_follows.question_id = questions.id
      WHERE
        question_follows.user_id = ?
    SQL

    results.map { |question_id| Question.find_by_id(question_id['id']) }
  end


  def self.most_followed_questions(n)
    results = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id
      FROM
        question_follows
      JOIN
        questions
        ON question_follows.question_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_follows.user_id)
      LIMIT ?
    SQL

    results.map { |question_id| Question.find_by_id(question_id['id']) }
  end

  attr_accessor :id, :user_id, :question_id

  def initialize(options = {})
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

class Reply < SuperTable

  # def self.find_by_id(id)
  #   results = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       replies
  #     WHERE
  #       replies.id = ?
  #   SQL
  #
  #   results.map { |result| Reply.new(result) }.first
  # end

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

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

class QuestionLike < SuperTable

  # def self.find_by_id(id)
  #   results = QuestionsDatabase.instance.execute(<<-SQL, id)
  #   SELECT
  #     *
  #   FROM
  #     question_likes
  #   WHERE
  #     question_likes.id = ?
  #   SQL
  #
  #   results.map { |result| QuestionLike.new(result) }.first
  # end

  def self.likers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.id
    FROM
      question_likes
    JOIN
      users
      ON question_likes.user_id = users.id
    WHERE
      question_likes.question_id = ?
    SQL

    results.map { |user_id| User.find_by_id(user_id['id']) }
  end

  def self.num_likes_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(users.id) AS count
      FROM
        question_likes
      JOIN
        users
        ON question_likes.user_id = users.id
      WHERE
        question_likes.question_id = ?
    SQL

    results.first['count']
  end

  def self.liked_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id
      FROM
        question_likes
      JOIN
        questions
        ON question_likes.question_id = questions.id
      WHERE
        question_likes.user_id = ?
    SQL

    results.map { |question_id| Question.find_by_id(question_id['id']) }

  end


  def self.most_liked_questions(n)
    results = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id
      FROM
        question_likes
      JOIN
        questions
        ON question_likes.question_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_likes.user_id)
      LIMIT ?
    SQL

    results.map { |question_id| Question.find_by_id(question_id['id']) }
  end


  attr_accessor :id, :user_id, :question_id

  def initialize(options = {})
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

end
