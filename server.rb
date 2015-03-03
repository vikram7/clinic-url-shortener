require 'sinatra'
require 'pg'
require 'pry'

def db_connection
  begin
    connection = PG.connect(dbname: "urls")
    yield(connection)
  ensure
    connection.close
  end
end

def encoder
  string = ""
  4.times do
    string += ("a".."z").to_a.sample
    string += rand(0..9).to_s
  end
  string
end

def is_in_db?(string)
  sql = "SELECT long FROM urls WHERE long = ($1)"
  check = db_connection do |conn|
    conn.exec(sql, [string])
  end
  check.first
end

get '/' do
  urls = db_connection do |conn|
    conn.exec("SELECT * FROM urls ORDER BY count DESC")
  end
  erb :index, locals: { urls: urls}
end

post '/' do
  long = params["url"]
  short = encoder

  if !is_in_db?(long)
    db_connection do |conn|
      conn.exec_params("INSERT INTO urls (long, short) VALUES ($1, $2)", [long, short])
    end
    redirect '/'
  else
    redirect '/error'
  end
end

get '/:short_url' do
  short = params["short_url"]
  long = db_connection do |conn|
    conn.exec("SELECT long FROM urls WHERE short = ($1)", [short])
  end
  long = long.first["long"]

  db_connection do |conn|
    conn.exec("UPDATE urls SET count = count + 1 WHERE short = ($1)", [short])
  end

  long = "http://" + long
  redirect long
end

get '/big/errror' do
  erb :errror
end

