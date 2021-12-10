require 'faker'
require 'json'

number_of_users = 12
number_of_events = 2
number_of_transactions = 40
number_of_offers = number_of_events * number_of_users

filepath = 'app/assets/data/kalshi.json'
kalshi_json = File.read(filepath)
kalshi_markets = JSON.parse(kalshi_json)


def end_event(event)
  last_transaction = event.concluded_transactions.last
  time = last_transaction.updated_at
  end_action_price = event.current_price >= 50 ? 100 : 0
  bank = User.find_by(email: 'crowdair@gmail.com')
  event.offers.destroy_all
  User.all.each do |user|
    actions_held = user.investments.where(event_id: event.id).first.n_actions
    t = Transaction.create!(
      seller_id: user.id,
      price: end_action_price,
      n_actions: actions_held,
      event_id: event.id,
      notified: true
    )
    t.update(buyer_id: bank.id, updated_at: time)
  end
  User.update_all_portfolios(time)
  event.archived = true
  event.save
end

def real_price(event, up_down)
  if event.transactions.last
    new_price = event.current_price + (rand(1...4) * [-1, 1, up_down].sample)
    while new_price > 100 || new_price < 1
      new_price = event.current_price + (rand(1...4) * [-1, 1, up_down].sample)
    end
    price = new_price
  else
    price = rand(0...100)
  end
  price
end

dates = []
number_of_transactions.times do
  dates << Faker::Time.between(from: 1.day.ago, to: DateTime.now)
end

dates.sort_by! { |s| s}
def valid_transaction_params
  event = Event.all.sample
  price = real_price(event, ((event.id % 3) -1))
  n_actions = rand(1..5)
  buyer, seller = User.all.where.not(admin: true).sample(2)  # Filter out the bank here
  actions_on_offer = event.transactions.where(buyer_id: nil, seller_id: seller.id).sum(:n_actions)
  seller_investments = seller.investments.find_by(event: event).n_actions

  while (price * n_actions) > buyer.points || n_actions > seller_investments - actions_on_offer
    event = Event.all.sample
    price = real_price(event, ((event.id % 3) -1))
    n_actions = rand(1..5)
    buyer, seller = User.all.where.not(admin: true).sample(2) # Same
    actions_on_offer = event.transactions.where(buyer_id: nil, seller_id: seller.id).sum(:n_actions)
    seller_investments = seller.investments.find_by(event: event).n_actions
  end
  {
    params: {
      price: price,
      n_actions: n_actions,
      seller: seller,
      event: event,
      notified: true
    },
    buyer: buyer
  }
end

puts "Destroying all Investment... 💣"
Investment.destroy_all
puts "Destroying all Transaction... 💣"
Transaction.destroy_all
puts "Destroying all Users... 💣"
User.destroy_all
puts "Destroying all Event... 💣"
Event.destroy_all

users_list = [
  {
    username: "End of event",
    email: "crowdair@gmail.com",
    password: "abcdef",
    points: 10_000_000,
    admin: true,
    avatar: Faker::Avatar.image
  },
  {
    username: "marcel",
    email: "mbower@gmail.com",
    password: "abcdef",
    avatar: Faker::Avatar.image
  },
  {
    username: "jane",
    email: "janetarzan@hotmail.com",
    password: "abcdef",
    avatar: Faker::Avatar.image
  }
]

(number_of_users - 2).times do
  users_list << {
    username: Faker::Internet.unique.username,
    email: Faker::Internet.email,
    password: "abcdef",
    avatar: Faker::Avatar.image
  }
end

puts "Creating a seed of #{users_list.size} fake Users..."

users_list.each_with_index do |user, i|
  User.create!(user)
  print "> Created User ##{i + 1} \r"
end

puts "Users table now contains #{User.count} users."

puts "Creating a seed of #{number_of_events} fake events..."
number_of_events.times do
  kalshi_event = kalshi_markets["markets"].sample
  Event.create!({
    title: kalshi_event["title"].truncate(100),
    end_date: Faker::Time.forward(days: 100),
    description: kalshi_event["settle_details"].truncate(300),
    img_url: kalshi_event["image_url"]
  })
end
puts "Events table now contains #{Event.count} events."

#-----
puts "Creating OUR events..."

kalshi_event = kalshi_markets["markets"].sample
event_list = [
  {
    title: "La laponie fermera-t-elle ses frontières avant Noël ?",
    end_date: DateTime.civil_from_format( :local, 2021, 12, 25),
    description: "Le Premier ministre a annoncé l'exclusion des lutins des usines de production et a mentionné une possible fermeture des frontières avant Noël. Le pays ayant interdit la vaccination aux citoyens de plus de 300 ans, la tournée du père Noël pourrait être compromise cette année.",
    img_url: "https://cdn.unitycms.io/image/ocroped/2001,2000,1000,1000,0,0/UZ4OkoSwoYw/9sPE-eRJqesBCHFh0-tUJr.jpg"
  },
  {
    title: "La suisse gagnera-t-elle la coupe du monde 2022 ?",
    end_date: DateTime.civil_from_format( :local, 2022, 12, 22, 16),
    description: "Lors des derniers matchs de qualifications, l'équipe féminine suisse a dominé ses adversaires et s'est hissée au sommet du classement. Suisse et USA sont pressentis pour la finale, à moins qu'un énième accord secret avec la FIFA permette à d'autres pays de briller.",
    img_url: "https://www.football.ch/fr/PortalData/27/Resources/bilder/nationalteams/a-team-frauen/wm_quali/sui_sco/SUISCO_News.jpg"
  },
  {
    title: "Le batch 732 du Wagon Lausanne sera-il le dernier ?",
    end_date: DateTime.civil_from_format( :local, 2021, 12, 10, 18),
    description: "Une conférence de presse de M. Jaime est attendue en fin d'après-midi. Un employé a témoigné anonymement du ras-le-bol du directeur général de l'école lausannoise. Selon diverses sources, un conflit latent avec la soufflerie du bâtiment l'aurait poussé à bout de nerfs.",
    img_url: "https://blog.hopitalvs.ch/wp-content/uploads/2030/07/Burnout-epuisement-professionnel.jpg"
  },
]

our_events_id = []
event_list.each do |event|
  event_obj = Event.create!(event)
  our_events_id << event_obj.id
end

puts "Events table now contains #{Event.count} events."

#-----
puts "Creating a seed of #{number_of_transactions} fake transactions..."

number_of_transactions.times do |i|
  transaction_params = valid_transaction_params
  transaction = Transaction.create!(transaction_params[:params])
  transaction.update(buyer_id: transaction_params[:buyer].id, updated_at: dates[i])
  User.update_all_portfolios(dates[i])
  print "#{i + 1} transactions created \r"
end

puts "#{number_of_transactions} transactions created"
puts "Creating a seed of #{number_of_offers} fake offers..."


number_of_offers.times do |i|
  transaction = Transaction.create!(valid_transaction_params[:params])
  transaction.update(updated_at: Faker::Time.between(from: 1.day.ago, to: DateTime.now))
  print "#{i + 1} offers created \r"
end

puts "#{number_of_offers} offers created"

puts ""

# puts "Ending events"

# (number_of_events / 3).times do
#   event = Event.all.sample
#   while our_events_id.include?(event.id) || event.archived == true
#     event = Event.all.sample
#   end
#   end_event(event)
# end

puts "Users table now contains #{Transaction.count} Transactions."
puts "Users table now contains #{Investment.count} Investments."
puts "Portfolio table now contains #{Portfolio.count} portfolio counts."
