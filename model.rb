# Here you can find some rather mysterious method defined on User model
# (again - don't worry this code doesn't live in the wild, at least anymore)
#
# You don't know the internals or how those methods are being used but can you noticed
# some more or less obvious issues with this code?
#
# Let's prepare a secret gist with alternative approach and your thoughts about it!

# As I see is a general model of the user. But we can resolve many problems using 
# relations between other models. We can create relationships with Role and create 
# methods for the definition type of user role. It will help to save resources and
#change the count of database requests. I leave methods (is_thernary?, is_employer?, 
# is_collaborator?) because don't know where they are used in other places.
# On another side, we have duplicates and from my side wrong requests to the database. More
# easy change where to find_by. As result, we get the last value or nil, and these changes 
# will save iterations of the processor and grow velocity.
# The last comment is using the ternary operator for some methods. We have some duplicates
# of code and additional comparing.
# Changed code is bellow.


lass Role < ApplicationRecord
  has_many :users

  NAMES = [:tradesman, :employer, :collaborator]

  class << self
    NAMES.each do |name_constant|
      define_method("get_#{name_constant}") { where(name: name_constant.to_s).first_or_create }
    end
  end
end


class User < ApplicationRecord
  belongs_to :role

  def is_tradesman?
    @is_tradesman ||= tradesman?
  end

  def is_employer?
    @is_employer ||= employer?
  end

  def is_collaborator?
    @is_collaborator ||= collaborator?
  end

  def can_access_forum?(args)
    @job = args[:job]
    self == @job.creator || is_tradesman?
  end

  def creator?(job)
    job.creator == self
  end

  def already_quoted(job)
    Quote.where(user_id: id, job_id: job.id).count >=1
  end

  def previous_quote_id(job)
    quote = previous_quote(job)
    quote.nil? ? 0 : quote.id
  end

  def previous_quote(job)
    Quote.find_by(user_id: id, job_id: job.id)
  end
end
