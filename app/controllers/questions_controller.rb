class QuestionsController < ApplicationController
  load_and_authorize_resource :course
  load_and_authorize_resource :mission, through: :course
  load_and_authorize_resource :question, through: :mission

  def new
    @question.max_grade = 10
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @question }
    end
  end

  def create
    @question.creator = current_user
    @asm_qn = AsmQn.new
    @asm_qn.asm = @mission
    @asm_qn.qn = @question

    respond_to do |format|
      if @question.save && @asm_qn.save
        @mission.update_grade
        format.html { redirect_to course_mission_url(@course, @mission),
                      notice: 'Question successfully added.' }
        format.json { render json: @question, status: :created, location: @question }
      else
        format.html { render action: "new" }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @question.update_attributes(params[:question])
        @mission.update_grade
        format.html { redirect_to course_mission_question_url(@course, @mission, @question),
                      notice: 'Mission was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
  end
end
