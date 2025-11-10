require 'rails_helper'

RSpec.describe DashboardHelper, type: :helper do
  describe '#calculate_axis_max' do
    it 'returns 10 for nil value' do
      expect(helper.calculate_axis_max(nil)).to eq(10)
    end

    it 'returns 10 for zero value' do
      expect(helper.calculate_axis_max(0)).to eq(10)
    end

    it 'rounds up and adds padding' do
      result = helper.calculate_axis_max(85)
      expect(result).to be >= 100
    end

    it 'handles large values' do
      result = helper.calculate_axis_max(1250)
      expect(result).to be >= 1500
    end
  end

  describe '#calculate_step_size' do
    it 'returns 2 for nil value' do
      expect(helper.calculate_step_size(nil)).to eq(2)
    end

    it 'returns 2 for zero value' do
      expect(helper.calculate_step_size(0)).to eq(2)
    end

    it 'calculates appropriate step size' do
      result = helper.calculate_step_size(100, 5)
      expect(result).to be_a(Integer)
      expect(result).to be > 0
    end
  end

  describe '#format_currency' do
    it 'formats amount as currency' do
      result = helper.format_currency(100.50)
      expect(result).to include('100.50')
    end

    it 'includes dollar sign' do
      result = helper.format_currency(50)
      expect(result).to include('$')
    end
  end

  describe '#safe_divide' do
    it 'returns 0 for nil denominator' do
      expect(helper.safe_divide(10, nil)).to eq(0)
    end

    it 'returns 0 for zero denominator' do
      expect(helper.safe_divide(10, 0)).to eq(0)
    end

    it 'performs division correctly' do
      expect(helper.safe_divide(10, 2)).to eq(5.0)
    end

    it 'rounds to 2 decimal places' do
      expect(helper.safe_divide(10, 3)).to eq(3.33)
    end
  end

  describe '#format_time_interval' do
    it 'returns "0 min" for nil' do
      expect(helper.format_time_interval(nil)).to eq("0 min")
    end

    it 'returns "0 min" for zero' do
      expect(helper.format_time_interval(0)).to eq("0 min")
    end

    it 'formats minutes' do
      result = helper.format_time_interval(45)
      expect(result).to include("min")
    end

    it 'formats hours for values >= 60 minutes' do
      result = helper.format_time_interval(120)
      expect(result).to include("hrs")
    end

    it 'formats days for values >= 1440 minutes' do
      result = helper.format_time_interval(2880)
      expect(result).to include("days")
    end
  end

  describe '#chart_data_json' do
    it 'returns JSON string' do
      result = helper.chart_data_json(['A', 'B'], [1, 2], 'Test Data')
      expect(result).to be_a(String)
      parsed = JSON.parse(result)
      expect(parsed['labels']).to eq(['A', 'B'])
      expect(parsed['datasets'][0]['data']).to eq([1, 2])
    end

    it 'includes label name' do
      result = helper.chart_data_json(['A'], [1], 'Revenue')
      parsed = JSON.parse(result)
      expect(parsed['datasets'][0]['label']).to eq('Revenue')
    end
  end

  describe '#bar_chart_data_json' do
    it 'returns JSON string' do
      result = helper.bar_chart_data_json(['A', 'B'], [1, 2])
      expect(result).to be_a(String)
      parsed = JSON.parse(result)
      expect(parsed['labels']).to eq(['A', 'B'])
    end

    it 'uses bar chart styling' do
      result = helper.bar_chart_data_json(['A'], [1])
      parsed = JSON.parse(result)
      expect(parsed['datasets'][0]['backgroundColor']).to be_present
    end
  end

  describe '#multi_line_chart_data_json' do
    it 'handles multiple datasets' do
      datasets = [
        { label: 'Series 1', data: [1, 2, 3] },
        { label: 'Series 2', data: [4, 5, 6] }
      ]
      result = helper.multi_line_chart_data_json(['A', 'B', 'C'], datasets)
      parsed = JSON.parse(result)
      
      expect(parsed['datasets'].length).to eq(2)
      expect(parsed['datasets'][0]['label']).to eq('Series 1')
      expect(parsed['datasets'][1]['label']).to eq('Series 2')
    end

    it 'assigns different colors to datasets' do
      datasets = [
        { label: 'A', data: [1] },
        { label: 'B', data: [2] }
      ]
      result = helper.multi_line_chart_data_json(['X'], datasets)
      parsed = JSON.parse(result)
      
      color1 = parsed['datasets'][0]['borderColor']
      color2 = parsed['datasets'][1]['borderColor']
      expect(color1).not_to eq(color2)
    end
  end

  describe '#pie_chart_data_json' do
    it 'returns JSON string' do
      result = helper.pie_chart_data_json(['A', 'B'], [10, 20])
      parsed = JSON.parse(result)
      
      expect(parsed['labels']).to eq(['A', 'B'])
      expect(parsed['datasets'][0]['data']).to eq([10, 20])
    end

    it 'includes colors' do
      result = helper.pie_chart_data_json(['A'], [10])
      parsed = JSON.parse(result)
      
      expect(parsed['datasets'][0]['backgroundColor']).to be_present
    end
  end

  describe '#line_chart_options' do
    it 'returns JSON string' do
      result = helper.line_chart_options('Revenue', 100)
      expect(result).to be_a(String)
      parsed = JSON.parse(result)
      
      expect(parsed['responsive']).to be true
      expect(parsed['scales']).to be_present
    end

    it 'includes max value when provided' do
      result = helper.line_chart_options('Revenue', 100)
      parsed = JSON.parse(result)
      
      expect(parsed['scales']['y']['max']).to be_present
    end

    it 'works without max value' do
      result = helper.line_chart_options('Revenue', nil)
      parsed = JSON.parse(result)
      
      expect(parsed['scales']).to be_present
    end
  end

  describe '#bar_chart_options' do
    it 'returns JSON string' do
      result = helper.bar_chart_options('Orders', 50)
      parsed = JSON.parse(result)
      
      expect(parsed['responsive']).to be true
    end

    it 'includes max value when provided' do
      result = helper.bar_chart_options('Orders', 50)
      parsed = JSON.parse(result)
      
      expect(parsed['scales']['y']['max']).to be_present
    end
  end

  describe '#pie_chart_options' do
    it 'returns JSON string' do
      result = helper.pie_chart_options
      parsed = JSON.parse(result)
      
      expect(parsed['responsive']).to be true
      expect(parsed['plugins']['legend']).to be_present
    end

    it 'positions legend to the right' do
      result = helper.pie_chart_options
      parsed = JSON.parse(result)
      
      expect(parsed['plugins']['legend']['position']).to eq('right')
    end
  end
end

