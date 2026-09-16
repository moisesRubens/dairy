enum Unit 
{
  kg, 
  liters,
  amount;

  String get label => switch(this)
  {
    Unit.amount => 'amount',
    Unit.kg => 'kg',
    Unit.liters => 'L'
  };
}

enum Allocation 
{
  sales, 
  stock
}