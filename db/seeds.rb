require 'faker'
require 'json'


number_of_users = 8
number_of_events = 7
number_of_transactions = 399
number_of_offers = number_of_events * number_of_users

filepath = 'app/assets/data/kalshi.json'
kalshi_json = File.read(filepath)
kalshi_markets = JSON.parse(kalshi_json)


def end_event(event, time, end_action_price)
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
  dates << Faker::Time.between(from: 7.days.ago, to: DateTime.now)
end

dates.sort_by! { |s| s}
def valid_transaction_params
  event = Event.all.sample
  price = real_price(event, ((((event.id % 5)) %2) *-2) +1)
  n_actions = rand(1..5)
  buyer, seller = User.all.where.not(admin: true).sample(2)  # Filter out the bank here
  actions_on_offer = event.transactions.where(buyer_id: nil, seller_id: seller.id).sum(:n_actions)
  seller_investments = seller.investments.find_by(event: event).n_actions

  while (price * n_actions) > buyer.points || n_actions > seller_investments - actions_on_offer
    event = Event.all.sample
    price = real_price(event, ((((event.id % 5)) %2) *-2) +1)
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

puts "Destroying all Investment... ????"
Investment.destroy_all
puts "Destroying all Transaction... ????"
Transaction.destroy_all
puts "Destroying all Users... ????"
User.destroy_all
puts "Destroying all Event... ????"
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
    username: "Andreas",
    email: "mbower@gmail.com",
    password: "abcdef",
    avatar: Faker::Avatar.image
  },
  {
    username: "Medi",
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
    title: "La Laponie fermera-t-elle ses fronti??res avant No??l ?",
    end_date: DateTime.civil_from_format( :local, 2021, 12, 25),
    description: "Le Premier ministre a annonc?? l'exclusion des lutins des usines de production et a mentionn?? une possible fermeture des fronti??res avant No??l. Le pays ayant interdit la vaccination aux citoyens de plus de 300 ans, la tourn??e du p??re No??l pourrait ??tre compromise cette ann??e.",
    img_url: "https://cdn.unitycms.io/image/ocroped/2001,2000,1000,1000,0,0/UZ4OkoSwoYw/9sPE-eRJqesBCHFh0-tUJr.jpg"
  },
  {
    title: "La Suisse gagnera-t-elle la coupe du monde 2022 ?",
    end_date: DateTime.civil_from_format( :local, 2022, 12, 22),
    description: "Lors des derniers matchs de qualifications, l'??quipe f??minine suisse a domin?? ses adversaires et s'est hiss??e au sommet du classement. Suisse et USA sont pressentis pour la finale, ?? moins qu'un ??ni??me accord secret avec la FIFA permette ?? d'autres pays de briller.",
    img_url: "https://www.football.ch/fr/PortalData/27/Resources/bilder/nationalteams/a-team-frauen/wm_quali/sui_sco/SUISCO_News.jpg"
  },
  {
    title: "Le Wagon Lausanne existera-t-il en 2022 ?",
    end_date: DateTime.civil_from_format( :local, 2021, 12, 11),
    description: "Une conf??rence de presse de M. Jaime est attendue en fin d'apr??s-midi. Un employ?? a t??moign?? anonymement du ras-le-bol du directeur g??n??ral de l'??cole lausannoise. Selon diverses sources, un conflit latent avec la soufflerie du b??timent l'aurait pouss?? ?? bout de nerfs.",
    img_url: "https://blog.hopitalvs.ch/wp-content/uploads/2030/07/Burnout-epuisement-professionnel.jpg"
  },
    {
    title: "La 5G sera-t-elle impos??e pour le r??veillon?",
    end_date: DateTime.civil_from_format( :local, 2022, 01, 01),
    description: "La r??gle 5G, impos??e en Suisse-Allemande, franchira-t-elle la Sarine ? Les autorit??s sont en discussion et souhaitent s'entretenir avec les diff??rents corps de m??tier du canton. Une d??cision est attendue ?? 11:59 le 31.12.2021.",
    img_url: "https://cdnuploads.aa.com.tr/uploads/Contents/2020/04/24/thumbs_b_c_1e3f39537fef5f853f2d19526771b5d1.jpg?v=125110"
  },
  {
    title: "M. Karole Niezgoda parviendra-t-il enfin ?? obtenir une coupe de cheveux convenable d'ici No??l?",
    end_date: DateTime.civil_from_format( :local, 2021, 12, 25),
    description: "Selon des sources s??res, M. Niezgoda serait en possession d'une cire miracle pour pallier ?? son probl??me de coiffure. Cette derni??re serait faite de cire d'abeille afin de permettre la manipulation de cette touffe de cheveux plus ??paisse que l'Amazonie. Esp??rons que cette recette fonctionnera!",
    img_url: "https://cdn.unitycms.io/image/ocroped/1200,1200,1000,1000,0,0/uagTwv0dQeM/5tUjfPwM4iN9tmij_U57Th.jpg"
  },
  {
    title: "Le P??re No??l parviendra-il ?? ??viter Omicron d'ici le 24 d??cembre pour sa livraison de cadeaux?",
    end_date: DateTime.civil_from_format( :local, 2021, 12, 15),
    description: "Selon ses lutins, le P??re No??l est enferm?? dans sa maison afin d'??viter tout contact nocif pour son voyage plan??taire de distribution de cadeau. Esp??rons que ce dernier r??ussisse cet exploit!",
    img_url: "https://images.radio-canada.ca/q_auto,w_960/v1/ici-premiere/16x9/pere-noel-masque-covid-19.jpg"
  },
  {
    title: "SpaceX va annoncer son intention de cr??er une base lunaire avant F??vrier 2022.",
    end_date: DateTime.civil_from_format( :local, 2022, 01, 31),
    description: "L'ambitieux dirigeant Elon Musk ?? la t??te de son entreprise SpaceX a toujours exprim?? son envie de visiter les ??toiles. Ce projet passera-t-il par la fondation d'une base lunaire?",
    img_url: "https://www.esa.int/var/esa/storage/images/esa_multimedia/images/2019/07/artist_impression_of_a_moon_base_concept/19471139-2-eng-GB/Artist_impression_of_a_Moon_Base_concept.jpg"
  }
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

  # Close events at pre-selected transaction indeces
  if [80, 200, 400].include?(i)
    event = Event.all.sample
    while our_events_id.include?(event.id) || event.archived == true || event.current_price >= 50
      event = Event.all.sample
    end
    end_action_price = 100
    end_event(event, dates[i], end_action_price)
    puts "Closed an event with YES"
  elsif [120, 324].include?(i)
    event = Event.all.sample
    while our_events_id.include?(event.id) || event.archived == true || event.current_price < 50
      event = Event.all.sample
    end
    end_action_price = 0
    end_event(event, dates[i], end_action_price)
    puts "Closed an event with NO"
  end
end

puts "#{number_of_transactions} transactions created"
puts "Creating a seed of #{number_of_offers} fake offers..."


number_of_offers.times do |i|
  transaction = Transaction.create!(valid_transaction_params[:params])
  transaction.update(updated_at: Faker::Time.between(from: 1.day.ago, to: DateTime.now))
  print "#{i + 1} offers created \r"
end

puts "#{number_of_offers} offers created"
puts "Users table now contains #{Transaction.count} Transactions."
puts "Users table now contains #{Investment.count} Investments."
puts "Portfolio table now contains #{Portfolio.count} portfolio counts."
