class MessagesController < ApplicationController
  def create
    @chat_room = ChatRoom.find(params[:chat_room_id])
    @message = @chat_room.messages.build(message_params)
    @message.user = Current.user

    if @message.save
      head :ok
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def message_params
      params.require(:message).permit(:content)
    end
end

