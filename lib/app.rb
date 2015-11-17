require 'idea_box'
require 'redis'
require 'json'

class IdeaBoxApp < Sinatra::Base
  set :method_override, true
  set :root, 'lib/app'

  configure :development do
    register Sinatra::Reloader
    $redis = Redis.new
  end

  not_found do
    erb :error
  end

  get '/' do
    erb :index, locals: {ideas: IdeaStore.all.sort, idea: Idea.new(params)}
  end

  post '/' do
    idea = IdeaStore.create(params[:idea])
    $redis.publish("my_channel", params[:idea].to_json)
    redirect '/'
  end

  delete '/:id' do |id|
    IdeaStore.delete(id.to_i)
    redirect '/'
  end

  get '/:id/edit' do |id|
    idea = IdeaStore.find(id.to_i)
    erb :edit, locals: {idea: idea}
  end

  get '/search_tag' do
    tag = params["tag"]
    erb :index, locals: {ideas: IdeaStore.search_tag(tag)}
  end

  get '/search_description' do
    description_part = params["search_description"]
    erb :index, locals: {ideas: IdeaStore.search_description(description_part)}
  end

  put '/:id' do |id|
    IdeaStore.update(id.to_i, params[:idea])
    redirect '/'
  end

  post '/:id/like' do |id|
    idea = IdeaStore.find(id.to_i)
    idea.like!
    IdeaStore.update(id.to_i, idea.to_h)
    redirect '/'
  end
end
