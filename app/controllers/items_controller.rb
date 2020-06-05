class ItemsController < ApplicationController
  before_action :set_item, except: %i[index new create get_category_children get_category_grandchildren purchaseCompleted]
  before_action :set_card, only: %i[purchaseConfilmation pay]
  before_action :set_sending_destinations, only: %i[purchaseConfilmation] 
  before_action :set_api_key
  require 'payjp'

  def index
    @items = Item.all
    @categories = Category.order(:id)
  end

  def new
    @item = Item.new
    @item.images.new
    @category_parent = Category.where(ancestry: nil)
  end

  def get_category_children
    @category_children = Category.find("#{params[:parent_name]}").children
  end

  def get_category_grandchildren
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  def create
    @item = Item.new(item_params)
    if @item.save!
      redirect_to root_path
    else
      render :new
    end
  end

  def show
    @categories = Category.order(:id)
  end

  def edit; end

  def update
    if @item.update(item_params)
      redirect_to root_path
    else
      render :edit
    end
  end

  def destroy
    if @item.destroy
      redirect_to root_path
    else
      render :show
    end
  end

  def purchaseConfilmation
    if @card.blank?
      flash[:alert] = '購入前にクレジットカードを登録してください'
      redirect_to controller: "cards", action: "new"
    else
      set_item
      set_sending_destinations
      set_customer
      set_card_information
    end
  end

  def pay
    charge = Payjp::Charge.create(
      amount: @item.price, #支払金額を引っ張ってくる
      customer: @card.customer_id,  #顧客ID
      currency: 'jpy',              #日本円
    )
    # 後でbuyerと調整
    # @item_buyer = Item.find(params[:id])
    # @item_buyer.update( buyer_id: current_user.id )
    redirect_to purchaseCompleted_item_path #購入完了ページへ
  end

  def purchaseCompleted
  end

  private

  def item_params
    params.require(:item).permit(:name, :price,:introduction, :brand_id, :prefecture_code, :category_id, :trading_status, :size_id, :item_condition_id, :postage_payer_id, :postage_type_id, :preparation_day_id, images_attributes: %i[src _destroy id]).merge(seller_id: current_user.id)
  end

  def set_item
    @item = Item.find(params[:id])
  end

  def set_api_key
    Payjp.api_key = Rails.application.credentials[:payjp][:secret_key]
  end

  def set_customer # 保管した顧客IDでpayjpから情報取得
    @customer = Payjp::Customer.retrieve(@card.customer_id)
  end

  def set_card_information # 保管したカードIDでpayjpから情報取得、カード情報表示のためインスタンス変数に代入
    @card_information = @customer.cards.retrieve(@card.card_id)
  end

  def set_card
    @card = Card.where(user_id: current_user.id).first
  end

  def set_sending_destinations
    @address = SendingDestination.where(user_id: current_user.id).first
  end

end
