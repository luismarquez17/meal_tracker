module ApplicationHelper
  MESES = %w[Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre].freeze
  MESES_ABBR = %w[Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic].freeze
  DIAS = %w[Domingo Lunes Martes Miércoles Jueves Viernes Sábado].freeze

  def spanish_month_name(date)
    return "" unless date
    "#{MESES[date.month - 1]} #{date.year}"
  end

  def spanish_short_month(date)
    return "" unless date
    "#{MESES_ABBR[date.month - 1]} #{date.year}"
  end

  def spanish_full_date(date)
    return "" unless date
    "#{DIAS[date.wday]}, #{date.day} de #{MESES[date.month - 1]}"
  end
end
