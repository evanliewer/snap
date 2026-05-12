return unless Rails.env.development?

puts "Seeding Snap demo data…"

owner = User.find_or_create_by!(email_address: "host@example.com") do |u|
  u.name = "Demo Host"
  u.password = "password123"
  u.admin = true
end

player1 = User.find_or_create_by!(email_address: "player1@example.com") { |u| u.name = "Riley"; u.password = "password123" }
player2 = User.find_or_create_by!(email_address: "player2@example.com") { |u| u.name = "Jordan"; u.password = "password123" }

game = Game.find_or_initialize_by(title: "Weekend Adventure Hunt")
game.assign_attributes(
  owner: owner,
  description: "Capture moments around town for points. Photo scavenger hunt demo.",
  status: "active",
  starts_at: Time.current,
  auto_approve: true,
  show_leaderboard: true,
  allow_video: false
)
game.save!

red_team = game.teams.find_or_create_by!(name: "Red Pandas") { |t| t.color = "#EF4444" }
blue_team = game.teams.find_or_create_by!(name: "Blue Herons") { |t| t.color = "#3B82F6" }

[owner, player1, player2].each do |u|
  m = Membership.find_or_initialize_by(user: u, game: game)
  m.role = (u == owner ? "admin" : "player")
  m.team = (u == player1 ? red_team : (u == player2 ? blue_team : nil))
  m.save!
end

food_cat = game.mission_categories.find_or_create_by!(name: "Food & Drink") { |c| c.color = "#F59E0B"; c.position = 0 }
nature_cat = game.mission_categories.find_or_create_by!(name: "Nature") { |c| c.color = "#10B981"; c.position = 1 }
social_cat = game.mission_categories.find_or_create_by!(name: "Social") { |c| c.color = "#8B5CF6"; c.position = 2 }

missions = [
  { cat: food_cat, title: "Snap your morning coffee", desc: "Latte art encouraged.", points: 100 },
  { cat: food_cat, title: "A weird snack combo", desc: "The weirder, the more points.", points: 200, bonus_points: 50 },
  { cat: nature_cat, title: "A tree taller than you", desc: "Pose with the tree.", points: 150 },
  { cat: nature_cat, title: "A sunset photo", desc: "Golden hour bonus.", points: 250, requires_location: true },
  { cat: social_cat, title: "Team selfie", desc: "Every player in frame.", points: 300, required: true },
  { cat: social_cat, title: "High-five a stranger", desc: "Get their permission. Be safe.", points: 200, repeatable: true, max_submissions_per_team: 3 }
]

missions.each_with_index do |m, idx|
  mission = game.missions.find_or_initialize_by(title: m[:title])
  mission.assign_attributes(
    mission_category: m[:cat],
    description: m[:desc],
    points: m[:points],
    bonus_points: m[:bonus_points] || 0,
    mission_type: "photo",
    position: idx,
    required: m[:required] || false,
    repeatable: m[:repeatable] || false,
    max_submissions_per_team: m[:max_submissions_per_team] || 1,
    requires_location: m[:requires_location] || false
  )
  mission.save!
end

puts "Done. Demo game join code: #{game.reload.join_code}"
puts "Log in as host@example.com / password123 to see the admin UI."
