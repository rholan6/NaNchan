require 'sinatra'
require 'sequel'
require 'sinatra/json'

enable :sessions

#general configuration: set up the database and models
configure do
    #Open Nanchan.db so we can potentially have content on this site
    DB = Sequel.connect('sqlite://NaNchan.db')

    #If we don't already have a table for threads, make one
    DB.create_table? :nanthreads do
        primary_key :id                              #Thread number
        String :subject                              #Basic topic (Provided by whoever mkes the first post)
        DateTime :newestPost                         #Intended to be used for "bumping" active threads to the top, but doesn't actually work
        foreign_key :originalpost_id, :originalposts #The first post of the thread (you can't have a thread with no posts)
    end

    #Make a table for posts if we don't have one yet
    DB.create_table? :posts do
        primary_key :id                         #Post number
        String :poster                          #Name of the person who made this post(if they give a name)
        String :imgurl                          #Image to display with this post
        String :content                         #The body of the post
        DateTime :postTime                      #Time the post was made
        foreign_key :nanthread_id, :nanthreads  #The thread this post is in
    end

    #Like a post, but special
    DB.create_table? :originalposts do
        primary_key :id       #Original post number
        String :poster        #Name of whoever made the post (if they give a name)
        String :imgurl        #Image to display
        String :content       #The body of the post
        DateTime :postTime    #Time the post was made
    end
end

#Now we start linking tables
#This is called Nanthread because Thread is, unsurprisingly, already in use
class Nanthread < Sequel::Model
    one_to_many :posts          #Each thread can have many posts
    many_to_one :originalposts  #Functionally a one to one, but we set it that way later
end

class Post < Sequel::Model
    many_to_one :nanthreads #There can be many posts in a thread
end

class Originalpost < Sequel::Model
  #Just remember: just because you can put one OP to many threads doesn't mean you should
  one_to_one :nanthreads
end

#What to do if someone starts a new thread
post '/newBread' do
    #Get the time for the first post
    rn = Time.now

    #Get the poster's name (which, in classic imageboard fashion, is Anonymous if they don't set a name)
    poster = params[:poster]
    if poster == ''
      poster = 'Anonymous'
    end
    
    #Make an Originalpost for... the original post
    op = Originalpost.create(:poster => poster,
    :imgurl => params[:imgurl],
    :content => params[:content],
    :postTime => rn)
    #Make the new thread now that we have a starting post to link it to
    newThread = Nanthread.create(:subject => params[:subject],
    :newestPost => rn,
    :originalpost_id => op[:id])
end

#What to do if someone makes a new post
post '/newPost' do
    #Get the current time (since posts like to know when they were made)
    rn = Time.now
    
    #Get the poster's name (again, Anonymous if they don't give one)
    poster = params[:poster]
    if poster == ''
        poster = 'Anonymous'
    end
    
    #Create a post with the given information (which thread it's in is given information)
    Post.create(:poster => poster,
    :imgurl => params[:imgurl],
    :content => params[:content],
    :postTime => rn,
    :nanthread_id => params[:thread_id])
    Nanthread.where(:id => params[:thread_id]).each do |bread|
        bread.newestPost = rn
    end
end

#Displays the homepage
get '/' do
    #Supposed to display threads from most to least recently posted in, but currently just displays them from most to least
    #recently created
    @all_threads = Nanthread.reverse_order(:newestPost)
    #views/NaNchan.erb
    erb :NaNchan
end

#Displays the thread with that id
get '/:id' do
    #Find the given thread
    @threadId = params[:id]
    @current = Nanthread.where(:id => @threadId)
    #Get the thread's subject
    @subject = @current[@threadId.to_i][:subject]
    #Get the original post
    @origin = Originalpost.where(:id => @threadId)
    #Get the other posts
    @all_replies = Post.where(:nanthread_id => @threadId)
    #Give this data to views/Thread.erb
    erb :Thread
end
