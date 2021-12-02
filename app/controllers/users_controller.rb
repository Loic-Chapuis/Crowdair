class UsersController < ApplicationController
  def show
    @user = current_user
    Event.joins(buyer_transactions: :current_user)
    @investments = @user.investments
    @transactions = current_user.transactions.where.not(buyer_id: nil).order(updated_at: :desc)#.limit(12)
    @latest_transactions = @transactions.limit(12)
    @offers = current_user.transactions.where(buyer_id: nil)
    @total_participants = User.count
    @ranking_position = User.order(points: :desc).pluck(:id).find_index(@user.id) + 1

    # Compute data for portfolio graph in dashboard /!\ Not accurate! /!\
    balance = 0
    @points_history = {}
    @transactions.each do |transaction|
      factor = transaction.buyer == @user ? -1 : 1 # subtract if buying, add if selling
      balance += transaction.n_actions * transaction.price * factor
      @points_history[transaction.updated_at] = balance
    end
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)

    redirect_to(user_path)
  end

  def edit
    @user = current_user
  end
end
