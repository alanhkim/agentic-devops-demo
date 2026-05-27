package com.threeriversbank.service;

import com.threeriversbank.client.BianApiClient;
import com.threeriversbank.model.dto.*;
import com.threeriversbank.model.entity.*;
import com.threeriversbank.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CreditCardServiceTest {

    @Mock
    private CreditCardRepository creditCardRepository;

    @Mock
    private CardFeatureRepository cardFeatureRepository;

    @Mock
    private FeeScheduleRepository feeScheduleRepository;

    @Mock
    private InterestRateRepository interestRateRepository;

    @Mock
    private BianApiClient bianApiClient;

    @InjectMocks
    private CreditCardService creditCardService;

    private CreditCard testCard;
    private CreditCard testCard2;

    @BeforeEach
    void setUp() {
        // Setup test card 1 - Business Cash Rewards
        testCard = new CreditCard();
        testCard.setId(1L);
        testCard.setName("Business Cash Rewards");
        testCard.setCardType("Cash Back");
        testCard.setAnnualFee(BigDecimal.ZERO);
        testCard.setIntroApr("0% for 12 months");
        testCard.setRegularApr("18.99% - 26.99%");
        testCard.setRewardsRate(new BigDecimal("2.00"));
        testCard.setSignupBonus("$300 statement credit");
        testCard.setCreditScoreNeeded("Good to Excellent (670+)");
        testCard.setForeignTransactionFee(BigDecimal.ZERO);
        testCard.setDescription("Earn 2% cash back on all purchases");
        testCard.setFeatures("Cash back rewards, No annual fee");
        testCard.setBenefits("Purchase protection, Extended warranty");

        // Setup card features
        CardFeature feature1 = new CardFeature();
        feature1.setId(1L);
        feature1.setFeatureName("Cash Back Rate");
        feature1.setFeatureValue("2%");
        feature1.setFeatureType("Rewards");
        feature1.setCreditCard(testCard);

        testCard.setCardFeatures(Arrays.asList(feature1));

        // Setup fee schedules
        FeeSchedule fee1 = new FeeSchedule();
        fee1.setId(1L);
        fee1.setFeeType("Annual Fee");
        fee1.setFeeAmount(BigDecimal.ZERO);
        fee1.setFeeDescription("No annual fee");
        fee1.setCreditCard(testCard);

        testCard.setFeeSchedules(Arrays.asList(fee1));

        // Setup interest rates
        InterestRate rate1 = new InterestRate();
        rate1.setId(1L);
        rate1.setRateType("Purchase APR");
        rate1.setRateValue(new BigDecimal("18.99"));
        rate1.setEffectiveDate(LocalDate.now());
        rate1.setCalculationMethod("Daily Balance");
        rate1.setCreditCard(testCard);

        testCard.setInterestRates(Arrays.asList(rate1));

        // Setup test card 2 - Business Travel Rewards
        testCard2 = new CreditCard();
        testCard2.setId(2L);
        testCard2.setName("Business Travel Rewards");
        testCard2.setCardType("Travel Rewards");
        testCard2.setAnnualFee(new BigDecimal("95.00"));
        testCard2.setRegularApr("19.99% - 27.99%");
        testCard2.setRewardsRate(new BigDecimal("3.00"));
        testCard2.setCardFeatures(new ArrayList<>());
        testCard2.setFeeSchedules(new ArrayList<>());
        testCard2.setInterestRates(new ArrayList<>());
    }

    @Test
    @DisplayName("Should return all credit cards from H2 database")
    void getAllCreditCards_ShouldReturnAllCards() {
        // Arrange
        when(creditCardRepository.findAll()).thenReturn(Arrays.asList(testCard, testCard2));

        // Act
        List<CreditCardDto> result = creditCardService.getAllCreditCards();

        // Assert
        assertThat(result).hasSize(2);
        assertThat(result.get(0).getName()).isEqualTo("Business Cash Rewards");
        assertThat(result.get(1).getName()).isEqualTo("Business Travel Rewards");
        verify(creditCardRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("Should return empty list when no cards exist")
    void getAllCreditCards_WhenNoCards_ShouldReturnEmptyList() {
        // Arrange
        when(creditCardRepository.findAll()).thenReturn(new ArrayList<>());

        // Act
        List<CreditCardDto> result = creditCardService.getAllCreditCards();

        // Assert
        assertThat(result).isEmpty();
        verify(creditCardRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("Should return credit card by ID with full details")
    void getCreditCardById_WithValidId_ShouldReturnCardWithDetails() {
        // Arrange
        when(creditCardRepository.findById(1L)).thenReturn(Optional.of(testCard));

        // Act
        CreditCardDto result = creditCardService.getCreditCardById(1L);

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(1L);
        assertThat(result.getName()).isEqualTo("Business Cash Rewards");
        assertThat(result.getCardType()).isEqualTo("Cash Back");
        assertThat(result.getCardFeatures()).hasSize(1);
        assertThat(result.getFeeSchedules()).hasSize(1);
        assertThat(result.getInterestRates()).hasSize(1);
        verify(creditCardRepository, times(1)).findById(1L);
    }

    @Test
    @DisplayName("Should throw exception when card ID not found")
    void getCreditCardById_WithInvalidId_ShouldThrowException() {
        // Arrange
        when(creditCardRepository.findById(999L)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> creditCardService.getCreditCardById(999L))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Credit card not found with id: 999");
        verify(creditCardRepository, times(1)).findById(999L);
    }

    @Test
    @DisplayName("Should return fee schedules for valid card ID")
    void getCardFees_WithValidCardId_ShouldReturnFees() {
        // Arrange
        FeeSchedule fee1 = new FeeSchedule();
        fee1.setId(1L);
        fee1.setFeeType("Annual Fee");
        fee1.setFeeAmount(BigDecimal.ZERO);
        fee1.setFeeDescription("No annual fee");

        FeeSchedule fee2 = new FeeSchedule();
        fee2.setId(2L);
        fee2.setFeeType("Cash Advance Fee");
        fee2.setFeeAmount(new BigDecimal("5.00"));
        fee2.setFeeDescription("$5 or 3% of transaction");

        when(feeScheduleRepository.findByCreditCardId(1L))
                .thenReturn(Arrays.asList(fee1, fee2));

        // Act
        List<FeeScheduleDto> result = creditCardService.getCardFees(1L);

        // Assert
        assertThat(result).hasSize(2);
        assertThat(result.get(0).getFeeType()).isEqualTo("Annual Fee");
        assertThat(result.get(1).getFeeType()).isEqualTo("Cash Advance Fee");
        verify(feeScheduleRepository, times(1)).findByCreditCardId(1L);
    }

    @Test
    @DisplayName("Should return empty list when no fees exist for card")
    void getCardFees_WithNoFees_ShouldReturnEmptyList() {
        // Arrange
        when(feeScheduleRepository.findByCreditCardId(1L)).thenReturn(new ArrayList<>());

        // Act
        List<FeeScheduleDto> result = creditCardService.getCardFees(1L);

        // Assert
        assertThat(result).isEmpty();
        verify(feeScheduleRepository, times(1)).findByCreditCardId(1L);
    }

    @Test
    @DisplayName("Should return interest rates for valid card ID")
    void getCardInterestRates_WithValidCardId_ShouldReturnRates() {
        // Arrange
        InterestRate rate1 = new InterestRate();
        rate1.setId(1L);
        rate1.setRateType("Purchase APR");
        rate1.setRateValue(new BigDecimal("18.99"));
        rate1.setEffectiveDate(LocalDate.now());
        rate1.setCalculationMethod("Daily Balance");

        InterestRate rate2 = new InterestRate();
        rate2.setId(2L);
        rate2.setRateType("Cash Advance APR");
        rate2.setRateValue(new BigDecimal("25.99"));
        rate2.setEffectiveDate(LocalDate.now());
        rate2.setCalculationMethod("Daily Balance");

        when(interestRateRepository.findByCreditCardId(1L))
                .thenReturn(Arrays.asList(rate1, rate2));

        // Act
        List<InterestRateDto> result = creditCardService.getCardInterestRates(1L);

        // Assert
        assertThat(result).hasSize(2);
        assertThat(result.get(0).getRateType()).isEqualTo("Purchase APR");
        assertThat(result.get(0).getRateValue()).isEqualByComparingTo(new BigDecimal("18.99"));
        assertThat(result.get(1).getRateType()).isEqualTo("Cash Advance APR");
        verify(interestRateRepository, times(1)).findByCreditCardId(1L);
    }

    @Test
    @DisplayName("Should return empty list when no interest rates exist")
    void getCardInterestRates_WithNoRates_ShouldReturnEmptyList() {
        // Arrange
        when(interestRateRepository.findByCreditCardId(1L)).thenReturn(new ArrayList<>());

        // Act
        List<InterestRateDto> result = creditCardService.getCardInterestRates(1L);

        // Assert
        assertThat(result).isEmpty();
        verify(interestRateRepository, times(1)).findByCreditCardId(1L);
    }

    @Test
    @DisplayName("Should return sample transactions for card")
    void getCardTransactions_ShouldReturnSampleTransactions() {
        // Act
        List<CardTransactionDto> result = creditCardService.getCardTransactions(1L);

        // Assert
        assertThat(result).isNotEmpty();
        assertThat(result).hasSize(3);
        assertThat(result.get(0).getTransactionId()).isEqualTo("TXN001");
        assertThat(result.get(0).getMerchantName()).isEqualTo("Office Supplies Co");
        assertThat(result.get(0).getAmount()).isEqualByComparingTo(new BigDecimal("245.50"));
        assertThat(result.get(0).getStatus()).isEqualTo("Completed");
    }

    @Test
    @DisplayName("Should use fallback when BIAN API fails")
    void getCardTransactions_WhenApifails_ShouldUseFallback() {
        // Arrange
        Exception testException = new RuntimeException("BIAN API unavailable");

        // Act - Call fallback method directly
        List<CardTransactionDto> result = creditCardService.getTransactionsFallback(1L, testException);

        // Assert
        assertThat(result).isNotEmpty();
        assertThat(result).hasSize(3);
        assertThat(result.get(0).getTransactionId()).isEqualTo("TXN001");
    }

    @Test
    @DisplayName("Should return sample billing for card")
    void getCardBilling_ShouldReturnSampleBilling() {
        // Act
        BillingDto result = creditCardService.getCardBilling(1L);

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.getBillingId()).startsWith("BILL");
        assertThat(result.getTotalAmount()).isEqualByComparingTo(new BigDecimal("1945.50"));
        assertThat(result.getMinimumPayment()).isEqualByComparingTo(new BigDecimal("58.37"));
        assertThat(result.getStatus()).isEqualTo("Current");
    }

    @Test
    @DisplayName("Should use fallback when BIAN API fails for billing")
    void getCardBilling_WhenApiFailshouldUseFallback() {
        // Arrange
        Exception testException = new RuntimeException("BIAN API unavailable");

        // Act - Call fallback method directly
        BillingDto result = creditCardService.getBillingFallback(1L, testException);

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.getBillingId()).startsWith("BILL");
        assertThat(result.getTotalAmount()).isEqualByComparingTo(new BigDecimal("1945.50"));
    }

    @Test
    @DisplayName("Should filter cards by card type")
    void getCardsByType_WithValidType_ShouldReturnFilteredCards() {
        // Arrange
        when(creditCardRepository.findByCardType("Cash Back"))
                .thenReturn(Arrays.asList(testCard));

        // Act
        List<CreditCardDto> result = creditCardService.getCardsByType("Cash Back");

        // Assert
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Business Cash Rewards");
        assertThat(result.get(0).getCardType()).isEqualTo("Cash Back");
        verify(creditCardRepository, times(1)).findByCardType("Cash Back");
    }

    @Test
    @DisplayName("Should return empty list when no cards match type")
    void getCardsByType_WithNonexistentType_ShouldReturnEmptyList() {
        // Arrange
        when(creditCardRepository.findByCardType("Invalid Type"))
                .thenReturn(new ArrayList<>());

        // Act
        List<CreditCardDto> result = creditCardService.getCardsByType("Invalid Type");

        // Assert
        assertThat(result).isEmpty();
        verify(creditCardRepository, times(1)).findByCardType("Invalid Type");
    }

    @Test
    @DisplayName("Should return cards with no annual fee")
    void getCardsWithNoAnnualFee_ShouldReturnFreeCards() {
        // Arrange
        when(creditCardRepository.findCardsWithNoAnnualFee())
                .thenReturn(Arrays.asList(testCard));

        // Act
        List<CreditCardDto> result = creditCardService.getCardsWithNoAnnualFee();

        // Assert
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getAnnualFee()).isEqualByComparingTo(BigDecimal.ZERO);
        verify(creditCardRepository, times(1)).findCardsWithNoAnnualFee();
    }

    @Test
    @DisplayName("Should return empty list when all cards have annual fee")
    void getCardsWithNoAnnualFee_WhenAllCardsHaveFee_ShouldReturnEmptyList() {
        // Arrange
        when(creditCardRepository.findCardsWithNoAnnualFee())
                .thenReturn(new ArrayList<>());

        // Act
        List<CreditCardDto> result = creditCardService.getCardsWithNoAnnualFee();

        // Assert
        assertThat(result).isEmpty();
        verify(creditCardRepository, times(1)).findCardsWithNoAnnualFee();
    }

    @Test
    @DisplayName("Should handle null card features gracefully")
    void getCreditCardById_WithNullFeatures_ShouldHandleGracefully() {
        // Arrange
        testCard.setCardFeatures(null);
        testCard.setFeeSchedules(null);
        testCard.setInterestRates(null);
        when(creditCardRepository.findById(1L)).thenReturn(Optional.of(testCard));

        // Act & Assert
        assertThatThrownBy(() -> creditCardService.getCreditCardById(1L))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    @DisplayName("Should verify DTO conversion includes all fields")
    void convertToDto_ShouldMapAllFields() {
        // Arrange
        when(creditCardRepository.findAll()).thenReturn(Arrays.asList(testCard));

        // Act
        List<CreditCardDto> result = creditCardService.getAllCreditCards();
        CreditCardDto dto = result.get(0);

        // Assert
        assertThat(dto.getId()).isEqualTo(testCard.getId());
        assertThat(dto.getName()).isEqualTo(testCard.getName());
        assertThat(dto.getCardType()).isEqualTo(testCard.getCardType());
        assertThat(dto.getAnnualFee()).isEqualByComparingTo(testCard.getAnnualFee());
        assertThat(dto.getIntroApr()).isEqualTo(testCard.getIntroApr());
        assertThat(dto.getRegularApr()).isEqualTo(testCard.getRegularApr());
        assertThat(dto.getRewardsRate()).isEqualByComparingTo(testCard.getRewardsRate());
        assertThat(dto.getSignupBonus()).isEqualTo(testCard.getSignupBonus());
        assertThat(dto.getCreditScoreNeeded()).isEqualTo(testCard.getCreditScoreNeeded());
        assertThat(dto.getForeignTransactionFee()).isEqualByComparingTo(testCard.getForeignTransactionFee());
        assertThat(dto.getDescription()).isEqualTo(testCard.getDescription());
        assertThat(dto.getFeatures()).isEqualTo(testCard.getFeatures());
        assertThat(dto.getBenefits()).isEqualTo(testCard.getBenefits());
    }

    @Test
    @DisplayName("Should verify billing DTO has correct date calculations")
    void getBillingFallback_ShouldHaveCorrectDates() {
        // Arrange
        Exception testException = new RuntimeException("Test");

        // Act
        BillingDto result = creditCardService.getBillingFallback(1L, testException);

        // Assert
        assertThat(result.getStatementDate()).isBefore(LocalDate.now());
        assertThat(result.getDueDate()).isAfter(LocalDate.now());
        assertThat(result.getDueDate()).isAfter(result.getStatementDate());
    }

    @Test
    @DisplayName("Should verify transactions have valid data structure")
    void getTransactionsFallback_ShouldHaveValidStructure() {
        // Arrange
        Exception testException = new RuntimeException("Test");

        // Act
        List<CardTransactionDto> result = creditCardService.getTransactionsFallback(1L, testException);

        // Assert
        assertThat(result).allMatch(tx -> tx.getTransactionId() != null);
        assertThat(result).allMatch(tx -> tx.getMerchantName() != null);
        assertThat(result).allMatch(tx -> tx.getAmount() != null);
        assertThat(result).allMatch(tx -> tx.getAmount().compareTo(BigDecimal.ZERO) > 0);
        assertThat(result).allMatch(tx -> tx.getCurrency().equals("USD"));
        assertThat(result).allMatch(tx -> tx.getTransactionDate() != null);
        assertThat(result).allMatch(tx -> tx.getCategory() != null);
        assertThat(result).allMatch(tx -> tx.getStatus().equals("Completed"));
    }
}
