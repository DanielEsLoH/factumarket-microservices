# Customer Service - Seed Data
# Creates sample customers for testing

puts "🌱 Seeding Customer Service..."

customers_data = [
  {
    name: "Empresa ABC S.A.S",
    identification: "901234567-8",
    email: "contacto@empresaabc.com",
    address: "Calle 123 #45-67, Bogotá, Colombia"
  },
  {
    name: "Comercial XYZ Ltda",
    identification: "800987654-1",
    email: "ventas@comercialxyz.com",
    address: "Carrera 7 #32-16, Medellín, Colombia"
  },
  {
    name: "Distribuidora Nacional S.A",
    identification: "890567123-4",
    email: "info@distribuidoranacional.com",
    address: "Avenida 68 #25-10, Cali, Colombia"
  },
  {
    name: "Juan Pérez Gómez",
    identification: "1234567890",
    email: "juan.perez@gmail.com",
    address: "Calle 45 #12-34, Apartamento 501, Bogotá"
  },
  {
    name: "María Rodríguez López",
    identification: "9876543210",
    email: "maria.rodriguez@hotmail.com",
    address: "Carrera 15 #78-90, Casa 12, Barranquilla"
  }
]

customers_data.each do |customer_data|
  customer = Customer.find_or_create_by(identification: customer_data[:identification]) do |c|
    c.name = customer_data[:name]
    c.email = customer_data[:email]
    c.address = customer_data[:address]
  end

  if customer.persisted?
    puts "✅ Created customer: #{customer.name} (ID: #{customer.id})"
  else
    puts "❌ Failed to create customer: #{customer_data[:name]}"
    puts "   Errors: #{customer.errors.full_messages.join(', ')}"
  end
end

puts "\n✨ Customer Service seeding completed!"
puts "📊 Total customers: #{Customer.count}"
