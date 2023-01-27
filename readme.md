

## Description
Простая реализация стандарта ERC1155 на основе openzeppelin. Добавлена роль админа и минтера.

**Основная механика токена:**
1. Минтить может только адрес с ролью минтер.
2. Сжигать токены может владелец токена.
3. Владелец токена может переводить токены по одному и группой.

**Дополнительно реализовано:**
1. Остановка работы контракта. Постановка на паузу админом и снятие с паузы.
2. Смена базового uri толкьо администратором.

**Неочевидная логика:** при первом трансфере токена проставляется flag, который подразумевает lock токена. При сжигание токена флаг сбрасывается. Для проверки залочен токен или нет использовать метод.
``` js
  isTokenLocked(uint256 _id)
```

## Deployed adresses
**Mumbai contract address:** 0x542114229E52034c5c8b0De37951c9d47c4a184C

## Events
``` js
/**
 * @dev Emitted when the new URI link was set
 */
URISet(string URI); // TODO: событие изменилось

/**
 * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
 */
event TransferSingle(
  address indexed operator,
  address indexed from,
  address indexed to,
  uint256 id,
  uint256 value
);

/**
 * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
 * transfers.
 */
event TransferBatch(
  address indexed operator,
  address indexed from,
  address indexed to,
  uint256[] ids,
  uint256[] values
);
```