status :draft
satisfies_need 2012

multiple_choice :were_you_or_your_partner_born_on_or_before_6_april_1935? do
  option :yes => :did_you_marry_or_civil_partner_before_5_december_2005?
  option :no => :sorry
end

multiple_choice :did_you_marry_or_civil_partner_before_5_december_2005? do
  option :yes => :whats_the_husbands_date_of_birth?
  option :no => :whats_the_highest_earners_date_of_birth?

  calculate :income_measure do
    case responses.last
    when 'yes' then "husband"
    when 'no' then "highest earner"
    else
      raise SmartAnswer::InvalidResponse
    end
  end
end

date_question :whats_the_husbands_date_of_birth? do
  to { Date.parse('1 Jan 1896') }
  from { Date.today }

  save_input_as :birth_date
  next_node :whats_the_husbands_income?
end

date_question :whats_the_highest_earners_date_of_birth? do
  to { Date.parse('1 Jan 1896') }
  from { Date.today }

  save_input_as :birth_date
  next_node :whats_the_highest_earners_income?
end

personal_allowance = 8105
over_65_allowance = 10500
over_75_allowance = 10660

age_related_allowance_chooser = AgeRelatedAllowanceChooser.new(
  personal_allowance: personal_allowance,
  over_65_allowance: over_65_allowance,
  over_75_allowance: over_75_allowance)

calculator = MarriedCouplesAllowanceCalculator.new(
  maximum_mca: 7705,
  minimum_mca: 2960,
  income_limit: 25400,
  personal_allowance: personal_allowance)

money_question :whats_the_husbands_income? do
  save_input_as :income

  next_node do |response|
    if response.to_f >= 25400.0
      :paying_into_a_pension?
    else
      :husband_done
    end
  end
end

money_question :whats_the_highest_earners_income? do
  save_input_as :income

  next_node do |response|
    if response.to_f >= 25400.0
      :paying_into_a_pension?
    else
      :highest_earner_done
    end
  end
end


multiple_choice :paying_into_a_pension? do
  option :yes => :how_much_expected_contributions_before_tax?
  option :no => :how_much_expected_gift_aided_donations?
end

money_question :how_much_expected_contributions_before_tax? do
  save_input_as :gross_pension_contributions

  next_node :how_much_expected_contributions_with_tax_relief?
end

money_question :how_much_expected_contributions_with_tax_relief? do
  save_input_as :net_pension_contributions

  next_node :how_much_expected_gift_aided_donations?
end

money_question :how_much_expected_gift_aided_donations? do
  calculate :income do
    calculator.calculate_adjusted_net_income(income.to_f, (gross_pension_contributions.to_f || 0), (net_pension_contributions.to_f || 0), responses.last)
  end

  next_node do |response|
    if income_measure == "husband"
      :husband_done
    else
      :highest_earner_done
    end
  end
end

outcome :husband_done do
  precalculate :allowance do
    age_related_allowance = age_related_allowance_chooser.get_age_related_allowance(Date.parse(birth_date))
    calculator.calculate_allowance(age_related_allowance, income)
  end
end
outcome :highest_earner_done do
  precalculate :allowance do
    age_related_allowance = age_related_allowance_chooser.get_age_related_allowance(Date.parse(birth_date))
    calculator.calculate_allowance(age_related_allowance, income)
  end
end
outcome :sorry
