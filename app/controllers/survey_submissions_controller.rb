class SurveySubmissionsController < ApplicationController
  load_and_authorize_resource :course
  load_and_authorize_resource :survey, through: :course
  load_and_authorize_resource :survey_submission, through: :survey

  before_filter :allow_only_one_submission, only: [:new, :create]
  before_filter :load_general_course_data, only: [:show, :edit, :new]

  def new
    if @survey_submission.save
      respond_to do |format|
        format.html { redirect_to edit_course_survey_survey_submission_path(@course, @survey, @survey_submission) }
      end
    end
  end

  def create
    update
  end

  def edit
    @current_qn = @survey_submission.current_qn || 1
    @step = @current_qn

    if params[:_pos] && params[:_pos].to_i >= 1
      @step = params[:_pos].to_i
    else
      @step = 1
    end
  end

  def update

  end

  def show
    edit
  end

  def submit
    step =  params[:step].to_i
    redirect_url = edit_course_survey_survey_submission_path(@course, @survey, @survey_submission)
    unless params[:option]
      respond_to do |format|
        flash[:error] ="No option is selected."
        format.html {redirect_to  redirect_url + "?_pos=#{step}" }
      end
      return
    end

    question = @survey.survey_questions.where(id:params[:question]).first
    options = params[:option].keys.map {|k| k.to_i}
    if question.max_response < options.count
      flash[:error] ="Max response allowed is #{question.max_response}, but #{options.count} have been selected."
    else
      answers = question.survey_mrq_answers.where(user_course_id:curr_user_course)

      was_selected = answers.map{|ans| ans.option_id }
      was_selected.each_with_index do |id, index|
        unless options.include? id
          answers[index].option.decrease_count
          answers[index].destroy
        end
      end
      (options - was_selected).each do |id|
        answer = question.survey_mrq_answers.build
        answer.option_id = id
        answer.user_course = curr_user_course
        answer.save
        answer.option.increase_count
      end

      step += 1
      if answers.count == 0
        @survey_submission.current_qn = (@survey_submission.current_qn || 1) + 1
        @survey_submission.save

        if @survey_submission.done?
          @survey_submission.set_submitted
        end
      end
    end
    respond_to do |format|
      format.html {redirect_to redirect_url + "?_pos=#{step}"}
    end
  end

  private
  def allow_only_one_submission
    sub = @survey.submission_by(curr_user_course.id)
    if sub
      @survey_submission = sub
    else
      @survey_submission.user_course = curr_user_course
    end
    @survey_submission.set_started
  end
end