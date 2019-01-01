require "calendar_time_calculation.rb"
class AvailableHoursController < ApiController
    include CalendarTimeCalculation

    # This function return a range with the days of the week
    #   :return: days of the week
    #   :rtype: range
    private
    def week
        if params[:from] && params[:to]
            Time.zone.parse(params[:from])..Time.zone.parse(params[:to])
        else
            Time.current.beginning_of_week..Time.current.end_of_week
        end
    end

    # This function search the user account according to the current user given by params
    #   :return: instance variable account
    #   :rtype: instance-variable
    def account
        @account ||= Account.find_by!(username: params[:account])
    end

    # This function prepares the consultation schedule cpomputing the effective time per consultation
    #   :param  duration: Duration in minutes for each consultation
    #   :return result: schedule per day of the week  
    #       => ex: duration = 00:30 
    #              schedule = { "mon" => ["8:00, 8:30, 9:00, 9:30..."] }
    #   :rtype: dict
    def account_schedules(duration)
         result = {
            'mon' => [],
            'tue' => [],
            'wed' => [],
            'thu' => [],
            'fri' => [],
            'sat' => [],
            'sun' => []
         }
        schedule = account.configuration['schedule'].except('consultation_duration')
        schedule.each do |day, consultation|
            schedule[day].each do |range|
                range_time = range.split('-').map { |time| Time.zone.parse(time) }
                current_range = range_time.first

                until current_range >= range_time.last
                    result[day].push(current_range.to_formatted_s(:time))
                    current_range += duration
                end
            end

        result[day].sort!
        end

        result
    end

    # This function search all the schedules filtered by account and the week given
    #   :param  week: Range of days of the week
    #   :param  account: Active user account
    #   :return result: Consultation schedules of the week of the current account
    #   :rtype: object
    def consultation_schedules
        ConsultationSchedule.where(starts_at: week, account: account)
    end

    # This function gets the available time-blocks according to the available schedules of
    # consultation
    #   :param  week: Range of days of the week
    #   :param  account: Active user account
    #   :return result: Available time-blocks to fit a consultation schedule
    #                   in a given appointments schedule
    #   :rtype: jwson
    def index
        consultation_duration = account.configuration['schedule']['consultation_duration']
        schedules = account_schedules(consultation_duration.minutes)

        consultation_schedules.each do |schedule|
            day = schedule.starts_at.strftime('%a').downcase
            next if schedules[day].empty?
            rounded_times = CalendarTimeCalculation.round_times(account, schedule, consultation_duration, day)
            current_parsed_time = CalendarTimeCalculation.hour_parser(rounded_times.first)
            end_schedule_parsed = CalendarTimeCalculation.hour_parser(rounded_times.last)

            # Travel and block each slot from current to end
            until current_parsed_time >= end_schedule_parsed
                schedule_time_parsed = CalendarTimeCalculation.minute_parser(current_parsed_time)

                index = schedules[day].index(schedule_time_parsed)
                if index # Make sure the slot exists
                    schedules[day].delete_at(index) 
                end

                current_parsed_time += consultation_duration
            end

            last_val = schedules[day].index(rounded_times.last)
            # If Schedule ends after schedule ends parsed, delete the last slot
            if last_val and CalendarTimeCalculation.hour_parser(schedule.ends_at.strftime('%H:%M')) > end_schedule_parsed
               schedules[day].delete_at(last_val)
            end
        end

        render json: { hours: schedules }
    end

end
