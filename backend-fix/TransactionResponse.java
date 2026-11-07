package com.demo.Expense_api.dto.transaction;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
public class TransactionResponse {
    private UUID id;
    private UUID walletId;
    private String walletName;
    private String kind;
    private BigDecimal amount;
    private String title;
    private LocalDate transactionDate;
    private String categoryName;
    private String categoryIcon;
    private String categoryColorHex;
}