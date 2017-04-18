require 'rails_helper.rb'

feature 'Creating article' do
  scenario 'can create an article' do
    # 1. Go to root path (there will be a button to add a new article)
    visit '/'
    # 2. Click on the "New article" button
    click_link 'New article'
    # 3. Fill out the form - add a title  with at least 5 characters and a text with at least 100 characters
    fill_in 'Title', :with => 'Test this'
    fill_in 'Text', :with => 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.'
    # 4. Submit the form
    click_button 'Create Article'
    # 5. See the 'show' page of created article
    expect(page).to have_content('Test this')
  end
end
