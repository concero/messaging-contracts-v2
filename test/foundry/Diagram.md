View diagram with [Mermaid Live Editor](https://mermaid.live/edit)

Colors:
 - Base Contracts: Blue
 - Abstract Contracts: Red
 - Test Contracts: Green
 - Deploy Scripts: Orange
 - Mock Contracts: White

Lines:
 - Solid Lines: Inheritance
 - Dashed Lines: Imports

```mermaid
classDiagram
    %% Base Classes
    class Script
    class ERC20
    class Test

    %% Abstract Classes
    class ConceroTest
    class ConceroRouterTest
    class ConceroVerifierTest

    %% Test Contracts
    class SendMessage
    class Storage
    class VerifierOperator
    class WithdrawConceroFees

    %% Deploy Scripts
    class DeployMockCLFRouter
    class DeployConceroRouter
    class DeployConceroVerifier
    class DeployERC20

    %% Mock Contracts
    class MockERC20
    class MockCLFRouter

    %% Inheritance Relationships
    Script <|-- DeployConceroRouter
    Script <|-- DeployConceroVerifier
    Script <|-- DeployMockCLFRouter
    Script <|-- DeployERC20

    Test <|-- ConceroTest
    ConceroTest <|-- ConceroRouterTest
    ConceroTest <|-- ConceroVerifierTest

    ConceroRouterTest <|-- SendMessage
    ConceroRouterTest <|-- Storage

    ConceroVerifierTest <|-- VerifierOperator
    ConceroVerifierTest <|-- WithdrawConceroFees

    ERC20 <|-- MockERC20

    %% Import Relationships (Dashed Lines)
    DeployERC20 ..> ERC20
    DeployMockCLFRouter ..> MockCLFRouter

    %% Defining Class Styles for Readability
    class Script:::base
    class ERC20:::base
    class Test:::base
    class ConceroTest:::abstract
    class ConceroRouterTest:::abstract
    class ConceroVerifierTest:::abstract
    class SendMessage:::test
    class Storage:::test
    class VerifierOperator:::test
    class WithdrawConceroFees:::test
    class DeployMockCLFRouter:::deploy
    class DeployConceroRouter:::deploy
    class DeployConceroVerifier:::deploy
    class MockERC20:::mock
    class MockCLFRouter:::mock
    class DeployERC20:::deploy

    classDef base fill:#e6f3ff,stroke:#000000
    classDef abstract fill:#ffe6e6,stroke:#000000
    classDef test fill:#f0ffe6,stroke:#000000
    classDef deploy fill:#fff0e6,stroke:#000000
    classDef mock fill:#f9f9f9,stroke:#000000
```
