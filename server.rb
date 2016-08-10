require 'sinatra'
require 'sequel'
require 'sinatra/json'

enable :sessions

#general configuration: set up the database and models
configure do
    DB = Sequel.connect('sqlite://NaNchan.db')

    DB.create_table? :nanthreads do
        primary_key :id
        String :subject
        DateTime :newestPost
        foreign_key :originalpost_id, :originalposts
    end

    DB.create_table? :posts do
        primary_key :id
        String :poster
        String :imgurl
        String :content
        DateTime :postTime
        foreign_key :nanthread_id, :nanthreads
    end

    DB.create_table? :originalposts do
      primary_key :id
      String :poster
      String :imgurl
      String :content
      DateTime :postTime
    end

#    DB.create_table? :admins do
#        primary_key :id
#        String :username, :unique => true;
#        String :password
#    end
end

class Nanthread < Sequel::Model
  one_to_many :posts
  many_to_one :originalposts
end

class Post < Sequel::Model
  many_to_one :nanthreads
end

class Originalpost < Sequel::Model
  #Just remember: just because you can put one OP to many threads doesn't mean you should
  one_to_one :nanthreads
end

class Admin < Sequel::Model
end

post '/newBread' do
    rn = Time.now

    #puts newThread
    poster = params[:poster]
    if poster == ''
      poster = 'Anonymous'
    end
    #Nanthread.where(:newestPost => rn) do |new_bread|
    #  puts new_bread[:subject]
    #  puts new_bread[:newestPost]
    #  newThread = new_bread[:id]
    #end
    op = Originalpost.create(:poster => poster,
    :imgurl => params[:imgurl],
    :content => params[:content],
    :postTime => rn)
    newThread = Nanthread.create(:subject => params[:subject],
    :newestPost => rn,
    :originalpost_id => op[:id])
    #newThread.add_originalpost(op)
    #op.add_nanthread(newThread)
    #newThread.add_post(op)
    #return newThread[:id]
    #return {thread_id: newThread[:id]}
end

post '/newPost' do
  rn = Time.now
  poster = params[:poster]
  if poster == ''
    poster = 'Anonymous'
  end
  Post.create(:poster => poster,
  :imgurl => params[:imgurl],
  :content => params[:content],
  :postTime => rn,
  :nanthread_id => params[:thread_id])
  Nanthread.where(:id => params[:thread_id]).each do |bread|
    bread.newestPost = rn
  end
end

#individual pages
get '/' do
    @all_threads = Nanthread.reverse_order(:newestPost)
    erb :NaNchan
end

get '/:id' do
    @threadId = params[:id]
    @current = Nanthread.where(:id => @threadId)
    @subject = @current[@threadId.to_i][:subject]
    @origin = Originalpost.where(:id => @threadId)
    @all_replies = Post.where(:nanthread_id => @threadId)
    erb :Thread
end
