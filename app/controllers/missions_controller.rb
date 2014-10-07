class MissionsController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json do
        render json: MissionDatatable.new(view_context)
      end
      format.xml do
        @missions = Mission.all.order(:name).eager_load(:abilities, :flags)
        render :xml => @missions.to_xml(include: [:abilities, :flags])
      end
    end
  end

  def update
    UpdateMissionsWorker.perform_async
    flash[:success] = "Job added to queue.  Missions will be updated from wowdb.com shortly."
    redirect_to :back
  end
end