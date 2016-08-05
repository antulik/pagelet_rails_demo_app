class Comment < ApplicationRecord

  validates_presence_of :author_name, :message

end
