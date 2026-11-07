// service/TransactionService.java
package com.demo.Expense_api.service;

import com.demo.Expense_api.dto.transaction.TransactionResponse;
import com.demo.Expense_api.dto.wallet.BalanceSummaryResponse;
import com.demo.Expense_api.entity.Transaction;
import com.demo.Expense_api.repository.TransactionRepository;
import com.demo.Expense_api.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import com.demo.Expense_api.dto.transaction.TransactionRequest;
import com.demo.Expense_api.entity.Category;
import com.demo.Expense_api.entity.User;
import com.demo.Expense_api.entity.Wallet;
import com.demo.Expense_api.repository.CategoryRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final WalletRepository walletRepository;
    private final CategoryRepository categoryRepository;

    public List<TransactionResponse> getRecentTransactions(UUID userId) {
        return transactionRepository
                .findTop10ByUserIdOrderByTransactionDateDescCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public BalanceSummaryResponse getBalanceSummary(UUID userId) {
        YearMonth currentMonth = YearMonth.now();
        LocalDate start = currentMonth.atDay(1);
        LocalDate end = currentMonth.atEndOfMonth();

        return BalanceSummaryResponse.builder()
                .totalBalance(walletRepository.sumBalanceByUserId(userId))
                .totalIncome(transactionRepository.sumIncomeBetween(userId, start, end))
                .totalExpense(transactionRepository.sumExpenseBetween(userId, start, end))
                .build();
    }

    private TransactionResponse toResponse(Transaction t) {
        return TransactionResponse.builder()
                .id(t.getId())
                .walletId(t.getWallet() != null ? t.getWallet().getId() : null)
                .walletName(t.getWallet() != null ? t.getWallet().getName() : null)
                .kind(t.getKind().name())
                .amount(t.getAmount())
                .title(t.getTitle())
                .transactionDate(t.getTransactionDate())
                .categoryName(t.getCategory() != null ? t.getCategory().getName() : "Uncategorized")
                .categoryIcon(t.getCategory() != null ? t.getCategory().getIcon() : "more")
                .categoryColorHex(t.getCategory() != null ? t.getCategory().getColorHex() : "#929292")
                .build();
    }

    public List<TransactionResponse> getAllTransactions(UUID userId) {
        return transactionRepository.findByUserIdOrderByTransactionDateDescCreatedAtDesc(userId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @org.springframework.transaction.annotation.Transactional
    public TransactionResponse createTransaction(User user, TransactionRequest request) {
        Wallet wallet = walletRepository.findById(UUID.fromString(request.getWalletId()))
                .orElseThrow(() -> new IllegalArgumentException("Wallet not found"));

        if (!wallet.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("You don't have access to this wallet");
        }

        Transaction.Kind kind = Transaction.Kind.valueOf(request.getKind().toUpperCase());

        Category category = null;
        if (request.getCategoryId() != null && !request.getCategoryId().isBlank()) {
            category = categoryRepository.findById(UUID.fromString(request.getCategoryId()))
                    .orElse(null);
        }

        Transaction transaction = Transaction.builder()
                .user(user)
                .wallet(wallet)
                .category(category)
                .kind(kind)
                .amount(request.getAmount())
                .title(request.getTitle())
                .transactionDate(request.getTransactionDate())
                .build();

        Transaction saved = transactionRepository.save(transaction);

        // Update wallet balance
        if (kind == Transaction.Kind.INCOME) {
            wallet.setBalance(wallet.getBalance().add(request.getAmount()));
        } else {
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
        }
        walletRepository.save(wallet);

        return toResponse(saved);
    }

    @Transactional
    public void deleteTransaction(UUID userId, UUID transactionId) {
        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found"));

        if (!transaction.getUser().getId().equals(userId)) {
            throw new IllegalArgumentException("You don't have access to this transaction");
        }

        Wallet wallet = transaction.getWallet();

        // Reverse the original effect on the wallet balance
        if (transaction.getKind() == Transaction.Kind.INCOME) {
            wallet.setBalance(wallet.getBalance().subtract(transaction.getAmount()));
        } else {
            wallet.setBalance(wallet.getBalance().add(transaction.getAmount()));
        }
        walletRepository.save(wallet);

        transactionRepository.delete(transaction);
    }


}