package com.demo.Expense_api.service;

import com.demo.Expense_api.dto.wallet.WalletRequest;
import com.demo.Expense_api.dto.wallet.WalletResponse;
import com.demo.Expense_api.entity.User;
import com.demo.Expense_api.entity.Wallet;
import com.demo.Expense_api.entity.Transaction;
import com.demo.Expense_api.repository.TransactionRepository;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import com.demo.Expense_api.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WalletService {

    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;

    public List<WalletResponse> getWalletsForUser(UUID userId) {
        return walletRepository.findByUserId(userId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public BigDecimal getTotalBalance(UUID userId) {
        return walletRepository.sumBalanceByUserId(userId);
    }

    public int getWalletCount(UUID userId) {
        return walletRepository.findByUserId(userId).size();
    }

    @Transactional
    public WalletResponse createWallet(User user, WalletRequest request) {
        Wallet wallet = Wallet.builder()
                .user(user)
                .name(request.getName())
                .currencyCode(request.getCurrencyCode())
                .balance(request.getBalance())
                .icon(request.getIcon())
                .colorHex(request.getColorHex())
                .isDefault(request.isDefault())
                .build();

        Wallet savedWallet = walletRepository.save(wallet);
        // The opening amount is already in the balance. Record its income
        // without applying it to the wallet a second time.
        if (savedWallet.getBalance().compareTo(BigDecimal.ZERO) > 0) {
            transactionRepository.save(Transaction.builder()
                    .user(user)
                    .wallet(savedWallet)
                    .kind(Transaction.Kind.INCOME)
                    .amount(savedWallet.getBalance())
                    .title("Starting balance - " + savedWallet.getName())
                    .transactionDate(LocalDate.now())
                    .build());
        }
        return toResponse(savedWallet);
    }

    @Transactional
    public WalletResponse updateWallet(UUID userId, UUID walletId, WalletRequest request) {
        Wallet wallet = walletRepository.findById(walletId)
                .orElseThrow(() -> new IllegalArgumentException("Wallet not found"));

        if (!wallet.getUser().getId().equals(userId)) {
            throw new IllegalArgumentException("You don't have access to this wallet");
        }

        BigDecimal addedAmount = request.getBalance().subtract(wallet.getBalance());

        wallet.setName(request.getName());
        wallet.setCurrencyCode(request.getCurrencyCode());
        wallet.setBalance(request.getBalance());
        wallet.setIcon(request.getIcon());
        wallet.setColorHex(request.getColorHex());
        wallet.setDefault(request.isDefault());

        Wallet savedWallet = walletRepository.save(wallet);
        if (addedAmount.signum() > 0) {
            transactionRepository.save(Transaction.builder()
                    .user(savedWallet.getUser())
                    .wallet(savedWallet)
                    .kind(Transaction.Kind.INCOME)
                    .amount(addedAmount)
                    .title("Balance added - " + savedWallet.getName())
                    .transactionDate(LocalDate.now())
                    .build());
        }
        return toResponse(savedWallet);
    }

    public void deleteWallet(UUID userId, UUID walletId) {
        Wallet wallet = walletRepository.findById(walletId)
                .orElseThrow(() -> new IllegalArgumentException("Wallet not found"));

        if (!wallet.getUser().getId().equals(userId)) {
            throw new IllegalArgumentException("You don't have access to this wallet");
        }

        walletRepository.delete(wallet);
    }

    private WalletResponse toResponse(Wallet wallet) {
        return WalletResponse.builder()
                .id(wallet.getId())
                .name(wallet.getName())
                .currencyCode(wallet.getCurrencyCode())
                .balance(wallet.getBalance())
                .icon(wallet.getIcon())
                .colorHex(wallet.getColorHex())
                .isDefault(wallet.isDefault())
                .build();
    }
}