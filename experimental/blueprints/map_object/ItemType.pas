unit ItemType;

interface

type
  TCollectibleItems = (
    ItemNone,

    { More of your items here }

    ItemCount
  );

  TInventoryItem = record
    active: boolean;  { isInUse can also be used }
    itemType: TCollectibleItems;
    value: integer;  { No multipliers for now }
    imgHandle: longint;
  end;
  
implementation

end.
