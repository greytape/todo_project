require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do 
  enable :sessions
  set :session_secret, 'secret'
end

before do 
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end  

get "/lists/:index/edit" do
  index = params[:index].to_i
  @list = session[:lists][index]
  erb :edit_list, layout: :layout
end

get "/lists/:index" do
  index = params[:index].to_i
  @list = session[:lists][index]
  @list_index = index
  erb :todo_lists
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error 
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { :name => list_name, :todos => []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Edit a list
post "/lists/:index" do
  index = params[:index].to_i
  new_list_name = params[:new_list_name].strip
  error = error_for_list_name(new_list_name)
  if error 
    session[:error] = error
    erb :edit_list
  else
    session[:lists][index][:name] = new_list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{index}"
  end 
end

post "/lists/:index/delete" do
  session[:lists].delete_at(params[:index].to_i)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

post "/lists/:list_index/todos" do 
  @list_index = params[:list_index].to_i
  @list = session[:lists][@list_index]
  text = params[:todo].strip
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :todo_lists, layout: :layout
  else
    @list[:todos] << {:name => text, :completed => false}
    session[:success] = "The todo was added."
    redirect "lists/#{@list_index}" 
  end
end

post "/lists/:list_index/todos/:todo_index/delete" do
  @list_index = params[:list_index].to_i
  todo_index = params[:todo_index].to_i
  @list = session[:lists][@list_index]
  @list[:todos].delete_at(todo_index)
  session[:success] = "The todo was deleted."
  erb :todo_lists, layout: :layout
end

post "/lists/:list_index/todos/:todo_index" do
  @list_index = params[:list_index].to_i
  todo_index = params[:todo_index].to_i
  @list = session[:lists][@list_index]
  is_completed = params[:completed] == "true"
  @list[:todos][todo_index][:completed] = is_completed
  if @list[:todos][todo_index][:completed]
    session[:success] = "The todo was marked completed."
  else
    session[:success] = "The todo was marked uncompleted."
  end
  redirect "/lists/#{@list_index}"
end

post "/lists/:list_index/complete_all" do
  @list_index = params[:list_index].to_i
  @list = session[:lists][@list_index]
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All todos marked complete."
  redirect "/lists/#{@list_index}"
end

get "/example" do
  @session = session[:lists]
  erb :example
end

helpers do
  # Return an error message if the name is invalid. Otherwise nil.
  
  def list_complete(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def list_class(list)
    "complete" if list_complete(list)
  end 

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def sort_lists(lists)
    lists.sort_by! { |list| list_complete(list) ? 1 : 0 }
  end

  def error_for_list_name(list_name)
    if session[:lists].any? { |list| list[:name] == list_name }
     "Sorry, that name has been used already."
    elsif !(1..200).cover?(list_name.size)
     "Name must be between 1 and 200 characters."
    end
  end

  def error_for_todo(todo_name)
    if !(1..200).cover?(todo_name.size)
     "Todo must be between 1 and 200 characters."
    end
  end
end



