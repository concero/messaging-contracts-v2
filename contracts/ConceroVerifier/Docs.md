
Colors: 
    - Core Contracts and Interfaces: #e6f3ff
    - Internal Libraries: #ffe6e6
    - Common Libraries: #fff0e6
    - Third-Party Dependencies: #f0ffe6
    - Main Class: #fafafa
Lines:
    - Inheritance Relationships: solid
    - Usage Relationships: dotted

```mermaid
classDiagram
    %% Core Contracts and Interfaces
    class ConceroOwnable
    class Base
    class CLF
    class Operator
    class Owner
    class GenericStorage
    class ConceroVerifier
    class IConceroVerifier

    %% Internal Libraries
    class Storage
    class Utils
    class Namespaces
    class Errors

    %% Common Libraries
    class GenericStorageLib
    class Constants
    class Signer
    class Decoder
    class FunctionsRequest

    %% Third-Party Dependencies
    class FunctionsClient
    class IERC20
    class SafeERC20

    %% Inheritance Relationships
    ConceroOwnable <|-- Base
    Base <|-- GenericStorage
    Base <|-- Owner
    FunctionsClient <|-- CLF
    CLF <|-- Operator
    CLF --|> Base
    CLF <|-- ConceroVerifier
    IConceroVerifier <|-- ConceroVerifier
    Operator <|-- ConceroVerifier
    Owner <|-- ConceroVerifier
    GenericStorage <|-- ConceroVerifier

    %% Usage Relationships (..>)
    Storage ..> GenericStorageLib
    Storage ..> Namespaces
    Storage ..> IConceroVerifier

    Utils ..> Storage
    Utils ..> Errors
    Utils ..> IConceroVerifier

    Base ..> Storage
    Base ..> Errors

    CLF ..> Errors
    CLF ..> Constants
    CLF ..> Utils
    CLF ..> Decoder
    CLF ..> Storage
    CLF ..> Signer
    CLF ..> FunctionsRequest
    CLF ..> IConceroVerifier

    Operator ..> IERC20
    Operator ..> SafeERC20
    Operator ..> Storage
    Operator ..> Constants
    Operator ..> IConceroVerifier
    Operator ..> Errors

    Owner ..> IERC20
    Owner ..> SafeERC20
    Owner ..> Storage

    GenericStorage ..> GenericStorageLib
    GenericStorage ..> Namespaces

    %% Defining Class Styles for Readability
    class ConceroVerifier:::main
    class Base:::contract
    class CLF:::contract
    class Operator:::contract
    class Owner:::contract
    class GenericStorage:::contract
    class ConceroOwnable:::contract

    class Storage:::internallib
    class Utils:::internallib
    class Namespaces:::internallib

    class GenericStorageLib:::commonlib
    class Signer:::commonlib
    class Decoder:::commonlib
    class Constants:::commonlib
    class Errors:::commonlib
    class FunctionsRequest:::commonlib

    class FunctionsClient:::thirdparty
    class IERC20:::thirdparty
    class SafeERC20:::thirdparty

    classDef main fill:#fafafa,stroke:#000000
    classDef contract fill:#e6f3ff,stroke:#000000
    classDef commonlib fill:#fff0e6,stroke:#000000
    classDef internallib fill:#ffe6e6,stroke:#000000
    classDef thirdparty fill:#f0ffe6,stroke:#000000
```
