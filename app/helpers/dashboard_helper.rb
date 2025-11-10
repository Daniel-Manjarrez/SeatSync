module DashboardHelper
  # Calculate nice axis range for charts
  def calculate_axis_max(max_value)
    return 10 if max_value.nil? || max_value <= 0

    # Round up to nearest nice number
    magnitude = 10 ** Math.log10(max_value).floor
    nice_max = ((max_value / magnitude.to_f).ceil * magnitude).to_i

    # Add 20% padding
    (nice_max * 1.2).to_i
  end

  # Calculate step size for axis labels
  def calculate_step_size(max_value, desired_steps = 5)
    return 2 if max_value.nil? || max_value <= 0

    raw_step = max_value / desired_steps.to_f
    magnitude = 10 ** Math.log10(raw_step).floor
    ((raw_step / magnitude).ceil * magnitude).to_i
  end

  # Format chart data as JSON for Chart.js
  def chart_data_json(labels, data, label_name = 'Data')
    {
      labels: labels,
      datasets: [{
        label: label_name,
        data: data,
        borderColor: '#10b981',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        borderWidth: 3,
        tension: 0.4,
        fill: true
      }]
    }.to_json.html_safe
  end

  # Format bar chart data
  def bar_chart_data_json(labels, data, label_name = 'Data')
    {
      labels: labels,
      datasets: [{
        label: label_name,
        data: data,
        backgroundColor: '#10b981',
        borderColor: '#059669',
        borderWidth: 1
      }]
    }.to_json.html_safe
  end

  # Format multi-dataset chart data
  def multi_line_chart_data_json(labels, datasets)
    colors = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6']

    formatted_datasets = datasets.map.with_index do |dataset, index|
      {
        label: dataset[:label],
        data: dataset[:data],
        borderColor: colors[index % colors.length],
        backgroundColor: "#{colors[index % colors.length]}20",
        borderWidth: 2,
        tension: 0.4
      }
    end

    {
      labels: labels,
      datasets: formatted_datasets
    }.to_json.html_safe
  end

  # Format pie/doughnut chart data
  def pie_chart_data_json(labels, data)
    colors = ['#001d06', '#003d0d', '#10b981', '#34d399', '#6ee7b7', '#a7f3d0']

    {
      labels: labels,
      datasets: [{
        data: data,
        backgroundColor: colors.first(labels.length),
        borderColor: '#1e293b',
        borderWidth: 2
      }]
    }.to_json.html_safe
  end

  # Calculate chart options with dynamic axes
  def line_chart_options(y_axis_label = 'Value', max_value = nil)
    calculated_max = max_value ? calculate_axis_max(max_value) : nil
    step_size = max_value ? calculate_step_size(max_value) : nil

    options = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          grid: {
            color: '#334155',
            drawBorder: true
          },
          ticks: {
            color: '#94a3b8'
          }
        },
        x: {
          grid: {
            display: false
          },
          ticks: {
            color: '#94a3b8'
          }
        }
      }
    }

    # Add max and step size if calculated
    if calculated_max && step_size
      options[:scales][:y][:max] = calculated_max
      options[:scales][:y][:ticks][:stepSize] = step_size
    end

    options.to_json.html_safe
  end

  # Bar chart options
  def bar_chart_options(y_axis_label = 'Value', max_value = nil)
    calculated_max = max_value ? calculate_axis_max(max_value) : nil
    step_size = max_value ? calculate_step_size(max_value) : nil

    options = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          grid: {
            color: '#334155',
            drawBorder: true
          },
          ticks: {
            color: '#94a3b8'
          }
        },
        x: {
          grid: {
            display: false
          },
          ticks: {
            color: '#94a3b8'
          }
        }
      }
    }

    if calculated_max && step_size
      options[:scales][:y][:max] = calculated_max
      options[:scales][:y][:ticks][:stepSize] = step_size
    end

    options.to_json.html_safe
  end

  # Pie chart options
  def pie_chart_options
    {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'right',
          labels: {
            color: '#94a3b8',
            padding: 15,
            font: {
              size: 12
            }
          }
        }
      }
    }.to_json.html_safe
  end

  # Format currency for display
  def format_currency(amount)
    number_to_currency(amount, precision: 2)
  end

  # Safe division to avoid divide by zero
  def safe_divide(numerator, denominator)
    return 0 if denominator.nil? || denominator.zero?
    (numerator.to_f / denominator).round(2)
  end

  # Format time in minutes to human-readable format
  def format_time_interval(minutes)
    return "0 min" if minutes.nil? || minutes.zero?

    minutes = minutes.to_f

    if minutes < 60
      "#{minutes.round(1)} min"
    elsif minutes < 1440 # Less than 24 hours
      hours = minutes / 60.0
      "#{hours.round(1)} hrs"
    else # Days
      days = minutes / 1440.0
      "#{days.round(1)} days"
    end
  end
end
