package com.demo.Expense_api;

import com.demo.Expense_api.dto.wallet.WalletRequest;
import com.demo.Expense_api.entity.*;
import com.demo.Expense_api.repository.*;
import com.demo.Expense_api.service.WalletService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class WalletIncomeTests {
    private final WalletRepository wallets = mock(WalletRepository.class);
    private final TransactionRepository transactions = mock(TransactionRepository.class);
    private final WalletService service = new WalletService(wallets, transactions);
    private final User user = new User();
    private final UUID walletId = UUID.randomUUID();

    @BeforeEach void setup() {
        user.setId(UUID.randomUUID());
        when(wallets.save(any(Wallet.class))).thenAnswer(call -> call.getArgument(0));
    }

    private WalletRequest request(String balance) {
        WalletRequest request = new WalletRequest();
        request.setName("Cash");
        request.setCurrencyCode("USD");
        request.setBalance(new BigDecimal(balance));
        return request;
    }

    private void existing(String balance) {
        when(wallets.findById(walletId)).thenReturn(Optional.of(Wallet.builder()
                .id(walletId).user(user).name("Cash").currencyCode("USD")
                .balance(new BigDecimal(balance)).build()));
    }

    private void income(String amount) {
        ArgumentCaptor<Transaction> captured = ArgumentCaptor.forClass(Transaction.class);
        verify(transactions).save(captured.capture());
        assertThat(captured.getValue().getKind()).isEqualTo(Transaction.Kind.INCOME);
        assertThat(captured.getValue().getAmount()).isEqualByComparingTo(amount);
        assertThat(captured.getValue().getUser()).isSameAs(user);
    }

    @Test void openingBalanceIsIncomeWithoutDoublingBalance() {
        assertThat(service.createWallet(user, request("500")).getBalance()).isEqualByComparingTo("500");
        income("500");
    }

    @Test void increaseRecordsOnlyAddedAmount() {
        existing("500");
        assertThat(service.updateWallet(user.getId(), walletId, request("700")).getBalance()).isEqualByComparingTo("700");
        income("200");
    }

    @Test void savingSameBalanceTwiceDoesNotDuplicateIncome() {
        existing("500");
        service.updateWallet(user.getId(), walletId, request("700"));
        service.updateWallet(user.getId(), walletId, request("700"));
        income("200");
    }

    @Test void unchangedAndReducedBalancesAreNotIncome() {
        existing("500");
        service.updateWallet(user.getId(), walletId, request("500"));
        service.updateWallet(user.getId(), walletId, request("400"));
        verifyNoInteractions(transactions);
    }

    @Test void zeroOpeningBalanceDoesNotCreateIncome() {
        service.createWallet(user, request("0"));
        verifyNoInteractions(transactions);
    }
}
